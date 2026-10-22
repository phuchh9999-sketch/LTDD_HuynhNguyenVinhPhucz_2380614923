using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuditAndWarningController : ControllerBase
    {
        private readonly KidGuardDbContext _context;

        public AuditAndWarningController(KidGuardDbContext context)
        {
            _context = context;
        }

        // ==================== 1. AUDIT LOGS (LỊCH SỬ THÊM / XÓA CỦA PHỤ HUYNH) ====================
        // GET: api/AuditAndWarning/audit?parentId=xxx
        [HttpGet("audit")]
        public async Task<IActionResult> GetAuditLogs([FromQuery] string? parentId)
        {
            var query = _context.ParentAuditLogs.AsQueryable();
            if (!string.IsNullOrEmpty(parentId))
            {
                query = query.Where(a => a.ParentId == parentId);
            }

            var logs = await query.OrderByDescending(a => a.CreatedAt).ToListAsync();
            return Ok(logs);
        }

        // POST: api/AuditAndWarning/audit (Ghi nhận lịch sử thao tác)
        [HttpPost("audit")]
        public async Task<IActionResult> CreateAuditLog([FromBody] ParentAuditLog log)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            log.CreatedAt = DateTime.UtcNow;
            _context.ParentAuditLogs.Add(log);
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã lưu vết nhật ký thao tác", Log = log });
        }

        // ==================== 2. STAFF INCIDENT REPORTS (NHÂN VIÊN BÁO CÁO LÊN ADMIN) ====================
        // GET: api/AuditAndWarning/staff-reports (Admin xem toàn bộ báo cáo từ nhân viên)
        [HttpGet("staff-reports")]
        public async Task<IActionResult> GetStaffReports()
        {
            var reports = await _context.StaffIncidentReports
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(reports);
        }

        // POST: api/AuditAndWarning/staff-reports (Nhân viên gửi báo cáo sự cố / bất thường lên Admin)
        [HttpPost("staff-reports")]
        public async Task<IActionResult> CreateStaffReport([FromBody] StaffIncidentReport report)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            report.CreatedAt = DateTime.UtcNow;
            report.Status = "Pending";
            _context.StaffIncidentReports.Add(report);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Status = true,
                Message = $"Đã gửi báo cáo sự cố '{report.Title}' lên Quản Trị Viên (Admin) thành công!",
                Report = report
            });
        }

        // PUT: api/AuditAndWarning/staff-reports/{id}/status (Admin cập nhật trạng thái xử lý)
        [HttpPut("staff-reports/{id}/status")]
        public async Task<IActionResult> UpdateReportStatus(int id, [FromBody] UpdateReportStatusDto dto)
        {
            var report = await _context.StaffIncidentReports.FindAsync(id);
            if (report == null) return NotFound(new { Message = "Không tìm thấy báo cáo" });

            report.Status = dto.Status;
            report.AdminNotes = dto.AdminNotes;
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã cập nhật trạng thái xử lý báo cáo", Report = report });
        }

        // ==================== 3. ADMIN WARNINGS (ADMIN CẢNH BÁO CHO PHỤ HUYNH) ====================
        // GET: api/AuditAndWarning/warnings?parentId=xxx (Phụ huynh xem danh sách cảnh báo của mình)
        [HttpGet("warnings")]
        public async Task<IActionResult> GetWarnings([FromQuery] string? parentId)
        {
            var query = _context.AdminWarnings.AsQueryable();
            if (!string.IsNullOrEmpty(parentId))
            {
                query = query.Where(w => w.ParentId == parentId);
            }

            var warnings = await query.OrderByDescending(w => w.CreatedAt).ToListAsync();
            return Ok(warnings);
        }

        // POST: api/AuditAndWarning/warnings (Admin phát đi cảnh báo tới Phụ huynh)
        [HttpPost("warnings")]
        public async Task<IActionResult> SendWarning([FromBody] AdminWarning warning)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            warning.CreatedAt = DateTime.UtcNow;
            warning.IsRead = false;
            _context.AdminWarnings.Add(warning);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Status = true,
                Message = $"Đã phát thông điệp cảnh báo tới phụ huynh {warning.ParentName ?? warning.ParentId} thành công!",
                Warning = warning
            });
        }

        // PUT: api/AuditAndWarning/warnings/{id}/read (Phụ huynh đánh dấu đã đọc)
        [HttpPut("warnings/{id}/read")]
        public async Task<IActionResult> MarkWarningRead(int id)
        {
            var warning = await _context.AdminWarnings.FindAsync(id);
            if (warning == null) return NotFound(new { Message = "Không tìm thấy cảnh báo" });

            warning.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã xác nhận đã đọc cảnh báo" });
        }
    }

    public class UpdateReportStatusDto
    {
        public string Status { get; set; } = "AdminReviewed"; // Pending, AdminReviewed, WarningIssued
        public string? AdminNotes { get; set; }
    }
}
