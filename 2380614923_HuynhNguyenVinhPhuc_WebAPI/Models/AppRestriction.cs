using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class AppRestriction
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ChildDeviceId { get; set; }

        [ForeignKey("ChildDeviceId")]
        public ChildDevice? ChildDevice { get; set; }

        [Required]
        [MaxLength(100)]
        public string AppName { get; set; } = string.Empty;

        [MaxLength(150)]
        public string PackageName { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Category { get; set; } = "Giải trí"; // Mạng xã hội, Game, Học tập, Giải trí

        [MaxLength(255)]
        public string? AppIcon { get; set; }

        public int DailyLimitMinutes { get; set; } = 30; // 0 = unlimited or use IsBlocked

        public bool IsBlocked { get; set; } = false; // Block completely

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
