using System.Net;
using System.Net.Mail;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Services
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _config;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration config, ILogger<EmailService> logger)
        {
            _config = config;
            _logger = logger;
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode)
        {
            try
            {
                var smtpServer = _config["EmailSettings:SmtpServer"] ?? "smtp.gmail.com";
                var portStr = _config["EmailSettings:SmtpPort"] ?? "587";
                int.TryParse(portStr, out int port);
                if (port == 0) port = 587;

                var senderEmail = _config["EmailSettings:SenderEmail"] ?? "phuchh9999@gmail.com";
                var senderPassword = _config["EmailSettings:SenderPassword"] ?? string.Empty;
                var senderName = _config["EmailSettings:SenderName"] ?? "KidGuard Security - Huỳnh Nguyễn Vĩnh Phúc (2380614923)";
                var enableSsl = bool.Parse(_config["EmailSettings:EnableSsl"] ?? "true");

                if (string.IsNullOrWhiteSpace(senderPassword))
                {
                    _logger.LogWarning("Chưa cấu hình SenderPassword (Mật khẩu ứng dụng 16 ký tự Gmail) trong appsettings.json. Mã OTP cho {toEmail} là: {otpCode}", toEmail, otpCode);
                    return false;
                }

                using var client = new SmtpClient(smtpServer, port)
                {
                    Credentials = new NetworkCredential(senderEmail, senderPassword.Replace(" ", "")),
                    EnableSsl = enableSsl,
                    Timeout = 10000
                };

                var mail = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = $"[KidGuard] Mã xác thực đăng nhập OTP của bạn: {otpCode}",
                    IsBodyHtml = true
                };

                mail.To.Add(toEmail);

                mail.Body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }}
        .card {{ max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }}
        .header {{ background: linear-gradient(135deg, #4f46e5 0%, #3b82f6 100%); color: white; padding: 32px 24px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 24px; font-weight: bold; letter-spacing: 0.5px; }}
        .header p {{ margin: 8px 0 0; opacity: 0.9; font-size: 13px; }}
        .content {{ padding: 32px 24px; color: #1e293b; line-height: 1.6; }}
        .otp-box {{ background: #f8fafc; border: 2px dashed #4f46e5; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }}
        .otp-code {{ font-size: 38px; font-weight: 800; letter-spacing: 8px; color: #4f46e5; font-family: monospace; }}
        .footer {{ background: #f8fafc; padding: 18px 24px; text-align: center; font-size: 11px; color: #64748b; border-top: 1px solid #e2e8f0; }}
    </style>
</head>
<body>
    <div class='card'>
        <div class='header'>
            <h1>KIDGUARD SECURITY</h1>
            <p>Hệ Thống Giám Sát & Bảo Vệ Trẻ Em</p>
        </div>
        <div class='content'>
            <p>Xin chào <strong>{fullName}</strong>,</p>
            <p>Bạn vừa thực hiện yêu cầu đăng nhập vào hệ thống <strong>KidGuard</strong>. Dưới đây là mã xác thực 2 bước (2FA OTP) của bạn:</p>
            <div class='otp-box'>
                <div style='font-size: 11px; text-transform: uppercase; color: #64748b; margin-bottom: 6px; font-weight: bold;'>MÃ XÁC THỰC OTP (HẠN 10 PHÚT)</div>
                <div class='otp-code'>{otpCode}</div>
            </div>
            <p style='color: #ef4444; font-size: 13px;'><strong>Lưu ý an toàn:</strong> Tuyệt đối không cung cấp mã OTP này cho bất kỳ ai để bảo vệ thông tin tài khoản và thiết bị của bé.</p>
            <p style='font-size: 12px; color: #64748b; margin-top: 24px;'>Sinh viên thực hiện: <strong>Huỳnh Nguyễn Vĩnh Phúc</strong> - MSSV: <strong>2380614923</strong> - Nhóm: <strong>goddy</strong></p>
        </div>
        <div class='footer'>
            Email này được gửi tự động từ máy chủ WebAPI KidGuard. Vui lòng không trả lời thư này.
        </div>
    </div>
</body>
</html>";

                await client.SendMailAsync(mail);
                _logger.LogInformation("Đã gửi thành công mã OTP {otpCode} tới {toEmail}", otpCode, toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gửi email OTP tới {toEmail}: {Message}", toEmail, ex.Message);
                return false;
            }
        }
    }
}
