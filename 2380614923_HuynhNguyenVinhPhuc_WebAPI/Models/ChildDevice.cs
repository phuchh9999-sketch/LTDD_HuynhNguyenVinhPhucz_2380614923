using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class ChildDevice
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string DeviceName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string ModelName { get; set; } = "Android Smartphone";

        [MaxLength(50)]
        public string OsVersion { get; set; } = "Android 14";

        [Required]
        [MaxLength(50)]
        public string DeviceCode { get; set; } = string.Empty; // QR Pairing code (e.g. KID-98234)

        public string? ParentId { get; set; }

        [ForeignKey("ParentId")]
        public User? Parent { get; set; }

        public string? ChildUserId { get; set; } // ID tài khoản của trẻ em (nếu bé đã tạo tài khoản)

        [Required]
        [MaxLength(100)]
        public string ChildName { get; set; } = string.Empty;

        public int DailyScreenTimeLimitMinutes { get; set; } = 120; // 2 hours default
        public int UsedScreenTimeMinutes { get; set; } = 35;

        public bool IsLocked { get; set; } = false;
        public int BatteryLevel { get; set; } = 85;

        // GPS Location tracking
        public double CurrentLatitude { get; set; } = 10.776889;
        public double CurrentLongitude { get; set; } = 106.700806;
        public string? CurrentAddress { get; set; } = "Quận 1, TP. Hồ Chí Minh";
        public DateTime LastLocationTime { get; set; } = DateTime.UtcNow;

        // Noise & Sensors
        public double CurrentNoiseLevel { get; set; } = 45.0; // in Decibels (dB)
        public bool IsOnline { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public ICollection<AppRestriction> AppRestrictions { get; set; } = new List<AppRestriction>();
        public ICollection<SecurityAlert> SecurityAlerts { get; set; } = new List<SecurityAlert>();
        public ICollection<SafeZone> SafeZones { get; set; } = new List<SafeZone>();
        public ICollection<HabitQuest> HabitQuests { get; set; } = new List<HabitQuest>();
    }
}
