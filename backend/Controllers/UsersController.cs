using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryAPI.Data;
using LibraryAPI.Models;

namespace LibraryAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly LibraryContext _context;

    public UsersController(LibraryContext context)
    {
        _context = context;
    }

    // GET: api/Users/5/dashboard
    [HttpGet("{id}/dashboard")]
    public async Task<ActionResult<UserDashboard>> GetUserDashboard(int id)
    {
        var user = await _context.Users
            .Include(u => u.BookRentals)
                .ThenInclude(br => br.Book)
            .Include(u => u.SeatReservations)
                .ThenInclude(sr => sr.Seat)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound();
        }

        var activeRentals = user.BookRentals
            .Where(br => br.ReturnDate == null)
            .ToList();

        var activeSeatReservation = user.SeatReservations
            .Where(sr => sr.EndTime > DateTime.UtcNow)
            .OrderByDescending(sr => sr.StartTime)
            .FirstOrDefault();

        var totalBooksRead = user.BookRentals
            .Where(br => br.ReturnDate != null)
            .Count();

        return Ok(new UserDashboard
        {
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            ActiveRentalCount = activeRentals.Count,
            ActiveRentals = activeRentals.Select(br => new RentalInfo
            {
                BookTitle = br.Book.Title,
                RentalDate = br.RentalDate,
                DueDate = br.DueDate,
                DaysRemaining = (br.DueDate - DateTime.UtcNow).Days
            }).ToList(),
            ActiveSeatNumber = activeSeatReservation?.Seat.SeatNumber,
            TotalBooksRead = totalBooksRead
        });
    }

    // GET: api/Users - Admin: Tüm kullanıcıları listele
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetUsers()
    {
        var users = await _context.Users
            .Select(u => new
            {
                u.Id,
                u.FirstName,
                u.LastName,
                u.Email,
                u.PhoneNumber,
                u.Role,
                u.IsActive,
                u.CreatedAt
            })
            .ToListAsync();

        return Ok(users);
    }

    // GET: api/Users/5 - Tek kullanıcı detayı
    [HttpGet("{id}")]
    public async Task<ActionResult<User>> GetUser(int id)
    {
        var user = await _context.Users.FindAsync(id);

        if (user == null)
        {
            return NotFound(new { message = "Kullanıcı bulunamadı" });
        }

        return Ok(new
        {
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.Role,
            user.IsActive,
            user.CreatedAt
        });
    }

    // POST: api/Users - Yeni kullanıcı oluştur
    [HttpPost]
    public async Task<ActionResult<User>> CreateUser(CreateUserDto dto)
    {
        // Email kontrolü
        if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
        {
            return BadRequest(new { message = "Bu email adresi zaten kullanılıyor" });
        }

        var user = new User
        {
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Email = dto.Email,
            Password = dto.Password, // Gerçek uygulamada hash'lenmeli
            PhoneNumber = dto.PhoneNumber,
            Role = dto.Role ?? "User",
            IsActive = dto.IsActive ?? true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, new
        {
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.Role,
            user.IsActive
        });
    }

    // PUT: api/Users/5 - Kullanıcı güncelle
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, UpdateUserDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound(new { message = "Kullanıcı bulunamadı" });
        }

        // Email değişiyorsa ve başka biri kullanıyorsa hata ver
        if (dto.Email != user.Email && await _context.Users.AnyAsync(u => u.Email == dto.Email))
        {
            return BadRequest(new { message = "Bu email adresi zaten kullanılıyor" });
        }

        user.FirstName = dto.FirstName;
        user.LastName = dto.LastName;
        user.Email = dto.Email;
        user.PhoneNumber = dto.PhoneNumber;
        user.Role = dto.Role;
        user.IsActive = dto.IsActive;

        if (!string.IsNullOrEmpty(dto.Password))
        {
            user.Password = dto.Password;
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.Role,
            user.IsActive
        });
    }

    // DELETE: api/Users/5 - Kullanıcı sil
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound(new { message = "Kullanıcı bulunamadı" });
        }

        // Aktif kiralamalar varsa silinemesin
        var hasActiveRentals = await _context.BookRentals
            .AnyAsync(br => br.UserId == id && br.ReturnDate == null);
        
        if (hasActiveRentals)
        {
            return BadRequest(new { message = "Aktif kiralaması olan kullanıcı silinemez" });
        }

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Kullanıcı silindi" });
    }
}

public class UserDashboard
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int ActiveRentalCount { get; set; }
    public List<RentalInfo> ActiveRentals { get; set; } = new();
    public string? ActiveSeatNumber { get; set; }
    public int TotalBooksRead { get; set; }
}

public class RentalInfo
{
    public string BookTitle { get; set; } = string.Empty;
    public DateTime RentalDate { get; set; }
    public DateTime DueDate { get; set; }
    public int DaysRemaining { get; set; }
}

public class CreateUserDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
}

public class UpdateUserDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Password { get; set; }
    public string? PhoneNumber { get; set; }
    public string Role { get; set; } = "User";
    public bool IsActive { get; set; } = true;
}
