using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class HabitQuest
    {
        [Key]
        public int Id { get; set; }

        public int ChildDeviceId { get; set; }

        [ForeignKey("ChildDeviceId")]
        public ChildDevice? ChildDevice { get; set; }

        [Required]
        [MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(300)]
        public string Description { get; set; } = string.Empty;

        public int RewardMinutes { get; set; } = 30; // Minutes added to screen time

        public bool IsCompleted { get; set; } = false;

        public bool IsApproved { get; set; } = false;

        [MaxLength(30)]
        public string ModerationStatus { get; set; } = "Approved"; // Approved, Flagged, Pending

        [MaxLength(300)]
        public string? StaffNotes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
