using Microsoft.AspNetCore.Identity;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class User : IdentityUser
    {
        public string? FullName { get; set; }
        public string? Initials { get; set; }
        public string? Role { get; set; } // Admin, Staff, Parent, Child
        public string? AvatarUrl { get; set; }
        public string? OtpCode { get; set; }
        public DateTime? OtpExpiry { get; set; }
        public string? FaceData { get; set; } // Vector/Face descriptor for Face Login
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string? ParentId { get; set; } // Khóa tham chiếu liên kết đến Phụ huynh nếu là tài khoản Trẻ em (Child)
        public bool HasFingerprint { get; set; } = false; // Đã kích hoạt đăng nhập vân tay
    }
}
