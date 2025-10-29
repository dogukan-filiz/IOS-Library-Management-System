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
