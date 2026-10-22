using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class SecurityAlert
    {
        [Key]
        public int Id { get; set; }

        public int ChildDeviceId { get; set; }

        [ForeignKey("ChildDeviceId")]
        public ChildDevice? ChildDevice { get; set; }

        [Required]
        [MaxLength(100)]
        public string ChildName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string AlertType { get; set; } = "SOS_MANUAL"; // SOS_MANUAL, HIGH_NOISE_BULLYING, FALL_SHAKE_IMPACT, GEOFENCE_EXIT

        [Required]
        [MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;

        public double Latitude { get; set; } = 10.776889;
        public double Longitude { get; set; } = 106.700806;

        public double NoiseDecibel { get; set; } = 0.0;

        [MaxLength(20)]
        public string Severity { get; set; } = "High"; // Low, Medium, High, Critical

        public bool IsResolved { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
