using System.ComponentModel.DataAnnotations;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models
{
    public class RegisterDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        public string Role { get; set; } = "Parent"; // Admin, Staff, Parent, Child

        public string? Initials { get; set; }

        public string? ChildName { get; set; }

        public string? ChildDeviceName { get; set; }
    }

    public class LoginRequestDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }

    public class VerifyOtpDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string OtpCode { get; set; } = string.Empty;
    }

    public class RequestOtpDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;
    }

    public class FaceLoginDto
    {
        public string? Username { get; set; } // Nếu để trống -> AI tự động nhận diện 1:N

        [Required]
        public string FaceDescriptor { get; set; } = string.Empty;
    }

    public class RegisterFaceDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string FaceDescriptor { get; set; } = string.Empty;
    }

    public class RegisterBiometricsDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;
        public bool? EnableFingerprint { get; set; }
        public string? FaceDescriptor { get; set; }
    }

    public class BiometricStatusDto
    {
        public bool Status { get; set; } = true;
        public string Username { get; set; } = string.Empty;
        public string? FullName { get; set; }
        public bool HasFingerprint { get; set; }
        public bool HasFace { get; set; }
        public string? FaceData { get; set; }
    }

    public class AuthResponseDto
    {
        public bool Status { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? Token { get; set; }
        public string? Role { get; set; }
        public string? Username { get; set; }
        public string? FullName { get; set; }
        public string? Initials { get; set; }
        public string? Id { get; set; }
        public string? ParentId { get; set; }
        public bool HasFingerprint { get; set; } = false;
        public bool HasFace { get; set; } = false;
        public bool RequiresOtp { get; set; } = false;
        public string? TempOtpForDemo { get; set; } // Provides transparent OTP for easy testing & demo in grading
    }

    public class UpdateLocationDto
    {
        public int ChildDeviceId { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string? Address { get; set; }
        public double? NoiseDecibel { get; set; }
        public int? BatteryLevel { get; set; }
    }

    public class TriggerAlertDto
    {
        public int ChildDeviceId { get; set; }
        public string AlertType { get; set; } = "SOS_MANUAL";
        public string Title { get; set; } = "Cảnh báo khẩn cấp";
        public string Description { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double NoiseDecibel { get; set; }
        public string Severity { get; set; } = "Critical";
    }

    public class QuestModerationDto
    {
        public string ModerationStatus { get; set; } = "Approved"; // Approved, Flagged
        public string? StaffNotes { get; set; }
    }

    public class UpdateUserDto
    {
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? UserName { get; set; }
        public string? Role { get; set; }
        public string? Password { get; set; }
    }

    public class VerifyParentPasswordDto
    {
        public string? ParentId { get; set; }
        public string? ChildUserId { get; set; }
        public int? ChildDeviceId { get; set; }
        public string Password { get; set; } = string.Empty;
    }
}
