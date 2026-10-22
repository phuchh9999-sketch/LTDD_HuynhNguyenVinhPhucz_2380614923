using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class ParentAuditLog
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(450)]
        public string ParentId { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? ParentName { get; set; }

        [Required]
        [MaxLength(50)]
        public string ActionType { get; set; } = "ADD_DEVICE"; // ADD_DEVICE, DELETE_DEVICE, LOCK_DEVICE, UNLOCK_DEVICE, ADD_QUEST, DELETE_QUEST, ADD_SAFE_ZONE, DELETE_SAFE_ZONE

        [Required]
        [MaxLength(150)]
        public string TargetName { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Details { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
