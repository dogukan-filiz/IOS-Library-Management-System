using System.ComponentModel.DataAnnotations;

namespace LibraryAPI.Models;

public class Book
{
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Title { get; set; } = string.Empty;

    [StringLength(100)]
    public string Author { get; set; } = string.Empty;

    [StringLength(13)]
    public string ISBN { get; set; } = string.Empty;

    public DateTime? PublishDate { get; set; }

    public bool IsAvailable { get; set; } = true;

    [StringLength(500)]
    public string? Description { get; set; }
}
