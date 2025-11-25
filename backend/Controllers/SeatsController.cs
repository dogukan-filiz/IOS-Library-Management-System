using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryAPI.Data;
using LibraryAPI.Models;

namespace LibraryAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SeatsController : ControllerBase
{
    private readonly LibraryContext _context;

    public SeatsController(LibraryContext context)
    {
        _context = context;
    }

    // GET: api/Seats
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetSeats()
    {
        var now = DateTime.UtcNow;
        
        var seats = await _context.Seats
            .OrderBy(s => s.Floor)
            .ThenBy(s => s.SeatNumber)
            .ToListAsync();

        // Get all active reservations for today and future
        var activeReservations = await _context.SeatReservations
            .Where(r => r.Status == "Aktif" && r.ReservationDate.Date >= now.Date)
            .ToListAsync();

        var seatsWithStatus = seats.Select(seat => {
            var reservations = activeReservations.Where(r => r.SeatId == seat.Id).ToList();
            
            string status = "available"; // Yeşil - Müsait
            
            if (reservations.Any())
            {
                // Check if seat is occupied right now
                var currentReservation = reservations.FirstOrDefault(r => 
                    r.ReservationDate.Date == now.Date &&
                    r.StartTime <= now &&
                    r.EndTime > now);
                
                if (currentReservation != null)
                {
                    status = "occupied"; // Kırmızı - Şu an dolu
                }
                else
                {
                    status = "reserved"; // Sarı - İleri tarihte rezerve
                }
            }
            
            return new
            {
                seat.Id,
                seat.SeatNumber,
                seat.Floor,
                seat.Section,
                seat.Type,
                seat.IsAvailable,
                Status = status
            };
        }).ToList();

        return Ok(seatsWithStatus);
    }

    // GET: api/Seats/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Seat>> GetSeat(int id)
    {
        var seat = await _context.Seats.FindAsync(id);

        if (seat == null)
        {
            return NotFound();
        }

        return seat;
    }

    // GET: api/Seats/available
    [HttpGet("available")]
    public async Task<ActionResult<IEnumerable<Seat>>> GetAvailableSeats()
    {
        var now = DateTime.Now;
        var occupiedSeatIds = await _context.SeatReservations
            .Where(r => r.ReservationDate.Date == now.Date 
                     && r.StartTime <= now
                     && r.EndTime >= now
                     && r.Status == "Aktif")
            .Select(r => r.SeatId)
            .Distinct()
            .ToListAsync();

        return await _context.Seats
            .Where(s => !occupiedSeatIds.Contains(s.Id))
            .OrderBy(s => s.Floor)
            .ThenBy(s => s.SeatNumber)
            .ToListAsync();
    }

    // POST: api/Seats
    [HttpPost]
    public async Task<ActionResult<Seat>> CreateSeat(Seat seat)
    {
        _context.Seats.Add(seat);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSeat), new { id = seat.Id }, seat);
    }

    // PUT: api/Seats/5
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSeat(int id, Seat seat)
    {
        if (id != seat.Id)
        {
            return BadRequest();
        }

        _context.Entry(seat).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!SeatExists(id))
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    // DELETE: api/Seats/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSeat(int id)
    {
        var seat = await _context.Seats.FindAsync(id);
        if (seat == null)
        {
            return NotFound();
        }

        _context.Seats.Remove(seat);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool SeatExists(int id)
    {
        return _context.Seats.Any(e => e.Id == id);
    }
}
