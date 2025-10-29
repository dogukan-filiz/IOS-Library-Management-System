using System.ComponentModel.DataAnnotations;

namespace LibraryAPI.Models
{
    public class BookRental
    {
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int BookId { get; set; }

        public DateTime RentalDate { get; set; } = DateTime.UtcNow;

        public DateTime DueDate { get; set; }

        public DateTime? ReturnDate { get; set; }

        [Required]
        public string Status { get; set; } = "Active"; // Active, Returned, Overdue

        public decimal? Fine { get; set; }

        public string? Notes { get; set; }

        // Navigation properties
        public User User { get; set; } = null!;
        public Book Book { get; set; } = null!;
    }
}
