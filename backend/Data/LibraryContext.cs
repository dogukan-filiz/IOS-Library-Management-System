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
    public DbSet<User> Users { get; set; }
    public DbSet<BookRental> BookRentals { get; set; }
    public DbSet<Seat> Seats { get; set; }
    public DbSet<SeatReservation> SeatReservations { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Book configuration
        modelBuilder.Entity<Book>()
            .HasIndex(b => b.ISBN)
            .IsUnique();

        // User configuration
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // Seat configuration
        modelBuilder.Entity<Seat>()
            .HasIndex(s => s.SeatNumber)
            .IsUnique();

        // BookRental relationships
        modelBuilder.Entity<BookRental>()
            .HasOne(br => br.User)
            .WithMany(u => u.BookRentals)
            .HasForeignKey(br => br.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<BookRental>()
            .HasOne(br => br.Book)
            .WithMany(b => b.BookRentals)
            .HasForeignKey(br => br.BookId)
            .OnDelete(DeleteBehavior.Restrict);

        // SeatReservation relationships
        modelBuilder.Entity<SeatReservation>()
            .HasOne(sr => sr.User)
            .WithMany(u => u.SeatReservations)
            .HasForeignKey(sr => sr.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SeatReservation>()
            .HasOne(sr => sr.Seat)
            .WithMany(s => s.SeatReservations)
            .HasForeignKey(sr => sr.SeatId)
            .OnDelete(DeleteBehavior.Restrict);

        // Seed data removed - using real database data now
    }
}
