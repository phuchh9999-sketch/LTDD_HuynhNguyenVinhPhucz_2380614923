using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class SafeZone
    {
        [Key]
        public int Id { get; set; }

        public string? ParentId { get; set; }

        [ForeignKey("ParentId")]
        public User? Parent { get; set; }

        public int? ChildDeviceId { get; set; }

        [ForeignKey("ChildDeviceId")]
        public ChildDevice? ChildDevice { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty; // e.g., "Nhà riêng", "Trường THPT", "Nhà Ông Bà"

        [MaxLength(255)]
        public string Address { get; set; } = string.Empty;

        public double Latitude { get; set; } = 10.776889;
        public double Longitude { get; set; } = 106.700806;

        public double RadiusMeters { get; set; } = 300.0; // Bán kính an toàn (mét)

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
