using System.ComponentModel.DataAnnotations;

namespace LibraryAPI.Models;

public class Book
{
    public int Id { get; set; }

    [Required]
    [StringLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Author { get; set; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string ISBN { get; set; } = string.Empty;

    public DateTime? PublishDate { get; set; }

    [StringLength(100)]
    public string? Publisher { get; set; }

    [StringLength(50)]
    public string? Category { get; set; }

    public int? PageCount { get; set; }

    [StringLength(1000)]
    public string? Description { get; set; }

    public string? CoverImageUrl { get; set; }

    public int TotalCopies { get; set; } = 1;

    public int AvailableCopies { get; set; } = 1;

    public bool IsAvailable { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<BookRental> BookRentals { get; set; } = new List<BookRental>();
}
