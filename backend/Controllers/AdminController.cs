using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryAPI.Data;
using LibraryAPI.Models;

namespace LibraryAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AdminController : ControllerBase
{
    private readonly LibraryContext _context;

    public AdminController(LibraryContext context)
    {
        _context = context;
    }

    // GET: api/Admin/stats
    [HttpGet("stats")]
    public async Task<ActionResult<DashboardStats>> GetDashboardStats()
    {
        var totalBooks = await _context.Books.CountAsync();
        var totalUsers = await _context.Users.CountAsync();
        var activeRentals = await _context.BookRentals
            .CountAsync(br => br.ReturnDate == null);
        var activeReservations = await _context.SeatReservations
            .CountAsync(sr => sr.ReservationDate >= DateTime.UtcNow && sr.Status == "Aktif");

        var stats = new DashboardStats
        {
            TotalBooks = totalBooks,
            TotalUsers = totalUsers,
            ActiveRentals = activeRentals,
            ActiveReservations = activeReservations
        };

        return Ok(stats);
    }

    // GET: api/Admin/users/{userId}/stats
    [HttpGet("users/{userId}/stats")]
    public async Task<ActionResult<UserStats>> GetUserStats(int userId)
    {
        var totalBooks = await _context.Books.CountAsync();
        var userRentals = await _context.BookRentals
            .Where(br => br.UserId == userId && br.ReturnDate == null)
            .CountAsync();
        var userReservations = await _context.SeatReservations
            .Where(sr => sr.UserId == userId && sr.ReservationDate >= DateTime.UtcNow && sr.Status == "Aktif")
            .CountAsync();

        var stats = new UserStats
        {
            TotalBooks = totalBooks,
            MyRentals = userRentals,
            MyReservations = userReservations
        };

        return Ok(stats);
    }
}

public class DashboardStats
{
    public int TotalBooks { get; set; }
    public int TotalUsers { get; set; }
    public int ActiveRentals { get; set; }
    public int ActiveReservations { get; set; }
}

public class UserStats
{
    public int TotalBooks { get; set; }
    public int MyRentals { get; set; }
    public int MyReservations { get; set; }
}
