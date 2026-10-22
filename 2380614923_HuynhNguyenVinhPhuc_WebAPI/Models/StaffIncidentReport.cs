using System.ComponentModel.DataAnnotations;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class StaffIncidentReport
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(450)]
        public string StaffId { get; set; } = string.Empty;

        [MaxLength(100)]
        public string StaffName { get; set; } = "Nhân viên hỗ trợ";

        [MaxLength(450)]
        public string? ParentId { get; set; }

        [MaxLength(100)]
        public string? ParentName { get; set; }

        public int? ChildDeviceId { get; set; }

        [MaxLength(100)]
        public string? ChildName { get; set; }

        [Required]
        [MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(1000)]
        public string Reason { get; set; } = string.Empty;

        [MaxLength(20)]
        public string Severity { get; set; } = "Warning"; // Warning, Critical

        [MaxLength(30)]
        public string Status { get; set; } = "Pending"; // Pending, AdminReviewed, WarningIssued

        [MaxLength(500)]
        public string? AdminNotes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
