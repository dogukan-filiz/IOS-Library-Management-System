using Microsoft.EntityFrameworkCore;
using LibraryAPI.Models;

namespace LibraryAPI.Data;

public class LibraryContext : DbContext
{
    public LibraryContext(DbContextOptions<LibraryContext> options)
        : base(options)
    {
    }

    public DbSet<Book> Books { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Seed data örneği
        modelBuilder.Entity<Book>().HasData(
            new Book
            {
                Id = 1,
                Title = "1984",
                Author = "George Orwell",
                ISBN = "9780451524935",
                PublishDate = new DateTime(1949, 6, 8),
                IsAvailable = true,
                Description = "Distopik kurgu klasiği"
            },
            new Book
            {
                Id = 2,
                Title = "Suç ve Ceza",
                Author = "Fyodor Dostoyevski",
                ISBN = "9780143058144",
                PublishDate = new DateTime(1866, 1, 1),
                IsAvailable = true,
                Description = "Psikolojik roman başyapıtı"
            }
        );
    }
}
