using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryAPI.Data;
using LibraryAPI.Models;

namespace LibraryAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BookRentalsController : ControllerBase
{
    private readonly LibraryContext _context;

    public BookRentalsController(LibraryContext context)
    {
        _context = context;
    }

    // POST: api/BookRentals
    [HttpPost]
    public async Task<ActionResult<BookRental>> RentBook(RentBookRequest request)
    {
        // Kullanıcının aktif kiralama sayısını kontrol et
        var activeRentalsCount = await _context.BookRentals
            .CountAsync(br => br.UserId == request.UserId && br.ReturnDate == null);

        if (activeRentalsCount >= 3)
        {
            return BadRequest(new { message = "Aynı anda en fazla 3 kitap kiralayabilirsiniz" });
        }

        // Kullanıcının bu kitabı zaten kiralamış olup olmadığını kontrol et
        var hasActiveRentalOfThisBook = await _context.BookRentals
            .AnyAsync(br => br.UserId == request.UserId && 
                           br.BookId == request.BookId && 
                           br.ReturnDate == null);

        if (hasActiveRentalOfThisBook)
        {
            return BadRequest(new { message = "Bu kitabı zaten kiralamışsınız. İade ettikten sonra tekrar kiralayabilirsiniz" });
        }

        // Kitabın müsaitliğini kontrol et
        var book = await _context.Books.FindAsync(request.BookId);
        if (book == null)
        {
            return NotFound(new { message = "Kitap bulunamadı" });
        }

        if (book.AvailableCopies <= 0)
        {
            return BadRequest(new { message = "Bu kitabın kopyası müsait değil" });
        }

        // Kiralama oluştur
        var rental = new BookRental
        {
            UserId = request.UserId,
            BookId = request.BookId,
            RentalDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(request.RentalDays),
        };

        _context.BookRentals.Add(rental);
        
        // Kitap kopyası sayısını azalt
        book.AvailableCopies--;
        if (book.AvailableCopies == 0)
        {
            book.IsAvailable = false;
        }

        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetBookRental), new { id = rental.Id }, rental);
    }

    // GET: api/BookRentals/5
    [HttpGet("{id}")]
    public async Task<ActionResult<BookRental>> GetBookRental(int id)
    {
        var rental = await _context.BookRentals
            .Include(br => br.Book)
            .Include(br => br.User)
            .FirstOrDefaultAsync(br => br.Id == id);

        if (rental == null)
        {
            return NotFound();
        }

        return rental;
    }

    // GET: api/BookRentals - Admin: Tüm kiralamaları listele
    [HttpGet]
    public async Task<ActionResult> GetAllRentals()
    {
        var rentals = await _context.BookRentals
            .Include(br => br.Book)
            .Include(br => br.User)
            .OrderByDescending(br => br.RentalDate)
            .Select(br => new
            {
                br.Id,
                br.UserId,
                br.BookId,
                br.RentalDate,
                br.DueDate,
                br.ReturnDate,
                br.Status,
                br.Fine,
                br.Notes,
                User = new
                {
                    br.User.Id,
                    br.User.FirstName,
                    br.User.LastName,
                    br.User.Email
                },
                Book = new
                {
                    br.Book.Id,
                    br.Book.Title,
                    br.Book.Author,
                    br.Book.ISBN,
                    br.Book.Category
                }
            })
            .ToListAsync();

        return Ok(rentals);
    }

    // GET: api/BookRentals/user/{userId}
    [HttpGet("user/{userId}")]
    public async Task<ActionResult> GetUserRentals(int userId)
    {
        var rentals = await _context.BookRentals
            .Include(br => br.Book)
            .Where(br => br.UserId == userId)
            .OrderByDescending(br => br.RentalDate)
            .Select(br => new
            {
                br.Id,
                br.UserId,
                br.BookId,
                br.RentalDate,
                br.DueDate,
                br.ReturnDate,
                br.Status,
                br.Fine,
                br.Notes,
                Book = new
                {
                    br.Book.Id,
                    br.Book.Title,
                    br.Book.Author,
                    br.Book.ISBN,
                    br.Book.Category
                }
            })
            .ToListAsync();

        return Ok(rentals);
    }

    // PUT: api/BookRentals/5/return
    [HttpPut("{id}/return")]
    public async Task<IActionResult> ReturnBook(int id)
    {
        var rental = await _context.BookRentals
            .Include(br => br.Book)
            .FirstOrDefaultAsync(br => br.Id == id);

        if (rental == null)
        {
            return NotFound();
        }

        if (rental.ReturnDate != null)
        {
            return BadRequest(new { message = "Bu kitap zaten iade edilmiş" });
        }

        rental.ReturnDate = DateTime.UtcNow;
        
        // Kitap kopyası sayısını artır
        rental.Book.AvailableCopies++;
        rental.Book.IsAvailable = true;

        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public class RentBookRequest
{
    public int UserId { get; set; }
    public int BookId { get; set; }
    public int RentalDays { get; set; } = 14; // Varsayılan 14 gün
}
