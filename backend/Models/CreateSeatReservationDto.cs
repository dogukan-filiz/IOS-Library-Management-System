namespace LibraryAPI.Models;

public class CreateSeatReservationDto
{
    public int UserId { get; set; }
    public int SeatId { get; set; }
    public DateTime ReservationDate { get; set; }
    public string StartTime { get; set; } = string.Empty; // "HH:mm:ss" format
    public string EndTime { get; set; } = string.Empty; // "HH:mm:ss" format
    public string Status { get; set; } = "Aktif";
}
