using System.ComponentModel.DataAnnotations;

namespace LibraryAPI.Models
{
    public class Seat
    {
        public int Id { get; set; }

        [Required]
        public string SeatNumber { get; set; } = string.Empty;

        [Required]
        public int Floor { get; set; }

        public string? Section { get; set; }

        public bool IsAvailable { get; set; } = true;

        [Required]
        public string Type { get; set; } = "Study"; // Study, Computer, Group

        // Navigation properties
        public ICollection<SeatReservation> SeatReservations { get; set; } = new List<SeatReservation>();
    }
}
