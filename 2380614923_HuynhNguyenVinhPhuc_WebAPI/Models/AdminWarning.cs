using System.ComponentModel.DataAnnotations;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class AdminWarning
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(450)]
        public string ParentId { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? ParentName { get; set; }

        [MaxLength(450)]
        public string? AdminId { get; set; }

        [MaxLength(100)]
        public string AdminName { get; set; } = "Quản trị viên hệ thống";

        [Required]
        [MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(1000)]
        public string Message { get; set; } = string.Empty;

        [MaxLength(20)]
        public string Severity { get; set; } = "Warning"; // Notice, Warning, Urgent

        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
