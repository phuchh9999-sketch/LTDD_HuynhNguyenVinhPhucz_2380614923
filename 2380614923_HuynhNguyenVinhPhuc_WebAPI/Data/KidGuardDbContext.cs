using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data
{
    public class KidGuardDbContext : IdentityDbContext<User>
    {
        public KidGuardDbContext(DbContextOptions<KidGuardDbContext> options) : base(options) { }

        public DbSet<ChildDevice> ChildDevices { get; set; }
        public DbSet<AppRestriction> AppRestrictions { get; set; }
        public DbSet<SafeZone> SafeZones { get; set; }
        public DbSet<SecurityAlert> SecurityAlerts { get; set; }
        public DbSet<HabitQuest> HabitQuests { get; set; }
        public DbSet<ParentAuditLog> ParentAuditLogs { get; set; }
        public DbSet<StaffIncidentReport> StaffIncidentReports { get; set; }
        public DbSet<AdminWarning> AdminWarnings { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            builder.Entity<User>().Property(u => u.Initials).HasMaxLength(10);
            builder.Entity<User>().Property(u => u.FullName).HasMaxLength(100);

            // ChildDevice relationships
            builder.Entity<ChildDevice>()
                .HasOne(d => d.Parent)
                .WithMany()
                .HasForeignKey(d => d.ParentId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.Entity<AppRestriction>()
                .HasOne(a => a.ChildDevice)
                .WithMany(d => d.AppRestrictions)
                .HasForeignKey(a => a.ChildDeviceId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<SafeZone>()
                .HasOne(s => s.ChildDevice)
                .WithMany(d => d.SafeZones)
                .HasForeignKey(s => s.ChildDeviceId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<SecurityAlert>()
                .HasOne(s => s.ChildDevice)
                .WithMany(d => d.SecurityAlerts)
                .HasForeignKey(s => s.ChildDeviceId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<HabitQuest>()
                .HasOne(h => h.ChildDevice)
                .WithMany(d => d.HabitQuests)
                .HasForeignKey(h => h.ChildDeviceId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
