using System.ComponentModel.DataAnnotations;

namespace LibraryAPI.Models
{
    public class SeatReservation
    {
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int SeatId { get; set; }

        public DateTime ReservationDate { get; set; } = DateTime.UtcNow;

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }

        [Required]
        public string Status { get; set; } = "Active"; // Active, Completed, Cancelled

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public User User { get; set; } = null!;
        public Seat Seat { get; set; } = null!;
    }
}
