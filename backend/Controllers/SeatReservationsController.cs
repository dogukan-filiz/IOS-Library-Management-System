using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryAPI.Data;
using LibraryAPI.Models;

namespace LibraryAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SeatReservationsController : ControllerBase
{
    private readonly LibraryContext _context;

    public SeatReservationsController(LibraryContext context)
    {
        _context = context;
    }

    // GET: api/SeatReservations - Admin: Tüm rezervasyonları listele
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetSeatReservations()
    {
        var reservations = await _context.SeatReservations
            .Include(sr => sr.User)
            .Include(sr => sr.Seat)
            .OrderByDescending(sr => sr.ReservationDate)
            .Select(sr => new
            {
                sr.Id,
                sr.UserId,
                sr.SeatId,
                sr.ReservationDate,
                sr.StartTime,
                sr.EndTime,
                sr.Status,
                sr.CreatedAt,
                User = new
                {
                    sr.User.Id,
                    sr.User.FirstName,
                    sr.User.LastName,
                    sr.User.Email
                },
                Seat = new
                {
                    sr.Seat.Id,
                    sr.Seat.SeatNumber,
                    sr.Seat.Floor,
                    sr.Seat.IsAvailable
                }
            })
            .ToListAsync();
            
        return Ok(reservations);
    }

    // GET: api/SeatReservations/5
    [HttpGet("{id}")]
    public async Task<ActionResult<SeatReservation>> GetSeatReservation(int id)
    {
        var reservation = await _context.SeatReservations
            .Include(sr => sr.User)
            .Include(sr => sr.Seat)
            .FirstOrDefaultAsync(sr => sr.Id == id);

        if (reservation == null)
        {
            return NotFound();
        }

        return reservation;
    }

    // GET: api/SeatReservations/user/5
    [HttpGet("user/{userId}")]
    public async Task<ActionResult<IEnumerable<object>>> GetUserReservations(int userId)
    {
        // Güncellenmiş rezervasyonları getir
        var reservations = await _context.SeatReservations
            .Include(sr => sr.Seat)
            .Where(sr => sr.UserId == userId)
            .OrderByDescending(sr => sr.ReservationDate)
            .Select(sr => new
            {
                sr.Id,
                sr.UserId,
                sr.SeatId,
                sr.ReservationDate,
                sr.StartTime,
                sr.EndTime,
                sr.Status,
                sr.CreatedAt,
                Seat = new
                {
                    sr.Seat.Id,
                    sr.Seat.SeatNumber,
                    sr.Seat.Floor,
                    sr.Seat.IsAvailable
                }
            })
            .ToListAsync();

        return Ok(reservations);
    }

    // GET: api/SeatReservations/seat/5
    [HttpGet("seat/{seatId}")]
    public async Task<ActionResult<IEnumerable<SeatReservation>>> GetSeatReservations(int seatId)
    {
        return await _context.SeatReservations
            .Where(sr => sr.SeatId == seatId && sr.Status == "Aktif")
            .OrderBy(sr => sr.ReservationDate)
            .ThenBy(sr => sr.StartTime)
            .ToListAsync();
    }

    // POST: api/SeatReservations
    [HttpPost]
    public async Task<ActionResult<SeatReservation>> CreateSeatReservation(CreateSeatReservationDto dto)
    {
        // Validation: Check if seat exists
        var seat = await _context.Seats.FindAsync(dto.SeatId);
        if (seat == null)
        {
            return BadRequest(new { message = "Koltuk bulunamadı" });
        }

        // Validation: Check if user exists
        var user = await _context.Users.FindAsync(dto.UserId);
        if (user == null)
        {
            return BadRequest(new { message = "Kullanıcı bulunamadı" });
        }

        // Parse time strings to DateTime
        DateTime startDateTime, endDateTime, reservationDateUtc;
        try
        {
            // Ensure reservation date is UTC
            reservationDateUtc = DateTime.SpecifyKind(dto.ReservationDate.Date, DateTimeKind.Utc);
            
            var startTimeParts = dto.StartTime.Split(':');
            var endTimeParts = dto.EndTime.Split(':');
            
            startDateTime = reservationDateUtc.AddHours(int.Parse(startTimeParts[0]))
                                              .AddMinutes(int.Parse(startTimeParts[1]))
                                              .AddSeconds(int.Parse(startTimeParts[2]));
            
            endDateTime = reservationDateUtc.AddHours(int.Parse(endTimeParts[0]))
                                            .AddMinutes(int.Parse(endTimeParts[1]))
                                            .AddSeconds(int.Parse(endTimeParts[2]));
        }
        catch
        {
            return BadRequest(new { message = "Geçersiz saat formatı" });
        }

        // Validation: End time must be after start time
        if (endDateTime <= startDateTime)
        {
            return BadRequest(new { message = "Bitiş saati başlangıç saatinden sonra olmalıdır" });
        }

        // Validation: Check for time conflicts
        var hasConflict = await _context.SeatReservations
            .AnyAsync(sr => sr.SeatId == dto.SeatId
                         && sr.ReservationDate.Date == reservationDateUtc.Date
                         && sr.Status == "Aktif"
                         && ((startDateTime >= sr.StartTime && startDateTime < sr.EndTime)
                          || (endDateTime > sr.StartTime && endDateTime <= sr.EndTime)
                          || (startDateTime <= sr.StartTime && endDateTime >= sr.EndTime)));

        if (hasConflict)
        {
            return BadRequest(new { message = "Bu koltuk seçtiğiniz zaman aralığında dolu" });
        }

        var reservation = new SeatReservation
        {
            UserId = dto.UserId,
            SeatId = dto.SeatId,
            ReservationDate = reservationDateUtc,
            StartTime = startDateTime,
            EndTime = endDateTime,
            Status = "Aktif",
            CreatedAt = DateTime.UtcNow
        };

        _context.SeatReservations.Add(reservation);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSeatReservation), new { id = reservation.Id }, reservation);
    }

    // PUT: api/SeatReservations/5
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSeatReservation(int id, SeatReservation reservation)
    {
        if (id != reservation.Id)
        {
            return BadRequest();
        }

        _context.Entry(reservation).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!SeatReservationExists(id))
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    // DELETE: api/SeatReservations/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> CancelReservation(int id)
    {
        var reservation = await _context.SeatReservations.FindAsync(id);
        if (reservation == null)
        {
            return NotFound();
        }

        reservation.Status = "İptal";
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE: api/SeatReservations/user/{userId}/history
    [HttpDelete("user/{userId}/history")]
    public async Task<IActionResult> ClearUserHistory(int userId)
    {
        var now = DateTime.UtcNow;
        
        // Önce süresi dolmuş aktif rezervasyonları "Tamamlandı" olarak işaretle
        var expiredReservations = await _context.SeatReservations
            .Where(sr => sr.UserId == userId && sr.Status == "Aktif" && sr.EndTime < now)
            .ToListAsync();
            
        foreach (var reservation in expiredReservations)
        {
            reservation.Status = "Tamamlandı";
        }
        
        if (expiredReservations.Any())
        {
            await _context.SaveChangesAsync();
        }
        
        // Sadece aktif olmayan (iptal edilmiş, tamamlanmış, süresi dolmuş) rezervasyonları sil
        var inactiveReservations = await _context.SeatReservations
            .Where(sr => sr.UserId == userId && sr.Status != "Aktif")
            .ToListAsync();

        if (inactiveReservations.Any())
        {
            _context.SeatReservations.RemoveRange(inactiveReservations);
            await _context.SaveChangesAsync();
        }

        return Ok(new { message = $"{inactiveReservations.Count} rezervasyon silindi", count = inactiveReservations.Count });
    }

    private bool SeatReservationExists(int id)
    {
        return _context.SeatReservations.Any(e => e.Id == id);
    }
}
