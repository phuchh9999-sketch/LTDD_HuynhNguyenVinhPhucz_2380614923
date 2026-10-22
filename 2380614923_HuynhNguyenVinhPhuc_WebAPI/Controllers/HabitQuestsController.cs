using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HabitQuestsController : ControllerBase
    {
        private readonly KidGuardDbContext _context;

        public HabitQuestsController(KidGuardDbContext context)
        {
            _context = context;
        }

        // GET: api/HabitQuests/all (Dành cho nhân viên kiểm duyệt nhiệm vụ)
        [HttpGet("all")]
        public async Task<IActionResult> GetAll()
        {
            var quests = await _context.HabitQuests
                .Include(q => q.ChildDevice)
                .OrderByDescending(q => q.CreatedAt)
                .ToListAsync();

            return Ok(quests);
        }

        // GET: api/HabitQuests/device/5
        [HttpGet("device/{deviceId}")]
        public async Task<IActionResult> GetByDevice(int deviceId)
        {
            var quests = await _context.HabitQuests
                .Where(q => q.ChildDeviceId == deviceId)
                .OrderByDescending(q => q.CreatedAt)
                .ToListAsync();

            return Ok(quests);
        }

        // POST: api/HabitQuests (Phụ huynh tạo nhiệm vụ rèn luyện)
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] HabitQuest quest)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            quest.CreatedAt = DateTime.UtcNow;
            if (string.IsNullOrEmpty(quest.ModerationStatus))
            {
                quest.ModerationStatus = "Approved";
            }

            _context.HabitQuests.Add(quest);
            await _context.SaveChangesAsync();

            // Ghi nhận nhật ký hành động của phụ huynh
            var device = await _context.ChildDevices.FindAsync(quest.ChildDeviceId);
            if (device != null && !string.IsNullOrEmpty(device.ParentId))
            {
                _context.ParentAuditLogs.Add(new ParentAuditLog
                {
                    ParentId = device.ParentId,
                    ParentName = "Phụ huynh",
                    ActionType = "ADD_QUEST",
                    TargetName = quest.Title,
                    Details = $"Giao nhiệm vụ: '{quest.Title}' cho bé {device.ChildName} (Thưởng +{quest.RewardMinutes} phút)",
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }

            return Ok(new { Status = true, Message = "Đã giao nhiệm vụ rèn luyện mới cho bé", Quest = quest });
        }

        // PUT: api/HabitQuests/5/moderate (Nhân viên kiểm tra nhiệm vụ có đúng mực hay không)
        [HttpPut("{id}/moderate")]
        public async Task<IActionResult> ModerateQuest(int id, [FromBody] QuestModerationDto dto)
        {
            var quest = await _context.HabitQuests
                .Include(q => q.ChildDevice)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quest == null) return NotFound(new { Message = "Không tìm thấy nhiệm vụ" });

            quest.ModerationStatus = dto.ModerationStatus; // "Approved" hoặc "Flagged"
            quest.StaffNotes = dto.StaffNotes;
            await _context.SaveChangesAsync();

            var statusDesc = dto.ModerationStatus == "Approved" ? "Hợp chuẩn đúng mực" : "Cần xem xét / Có dấu hiệu vi phạm";
            return Ok(new
            {
                Status = true,
                Message = $"Đã kiểm duyệt nhiệm vụ: {statusDesc}",
                Quest = quest
            });
        }

        // PUT: api/HabitQuests/5/complete (Bé đánh dấu đã hoàn thành)
        [HttpPut("{id}/complete")]
        public async Task<IActionResult> MarkCompleted(int id)
        {
            var quest = await _context.HabitQuests.FindAsync(id);
            if (quest == null) return NotFound(new { Message = "Không tìm thấy nhiệm vụ" });

            quest.IsCompleted = true;
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Bé đã gửi báo cáo hoàn thành nhiệm vụ! Chờ phụ huynh duyệt thưởng.", Quest = quest });
        }

        // PUT: api/HabitQuests/5/approve (Phụ huynh duyệt thưởng thêm phút sử dụng)
        [HttpPut("{id}/approve")]
        public async Task<IActionResult> ApproveQuest(int id)
        {
            var quest = await _context.HabitQuests
                .Include(q => q.ChildDevice)
                .FirstOrDefaultAsync(q => q.Id == id);

            if (quest == null) return NotFound(new { Message = "Không tìm thấy nhiệm vụ" });

            quest.IsApproved = true;
            if (quest.ChildDevice != null)
            {
                // Cộng thêm hạn mức sử dụng máy cho trẻ
                quest.ChildDevice.DailyScreenTimeLimitMinutes += quest.RewardMinutes;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Status = true,
                Message = $"Phụ huynh đã duyệt! Đã cộng thêm +{quest.RewardMinutes} phút sử dụng máy cho bé.",
                NewScreenLimit = quest.ChildDevice?.DailyScreenTimeLimitMinutes
            });
        }

        // DELETE: api/HabitQuests/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var quest = await _context.HabitQuests.FindAsync(id);
            if (quest == null) return NotFound(new { Message = "Không tìm thấy nhiệm vụ" });

            _context.HabitQuests.Remove(quest);
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã xóa nhiệm vụ" });
        }
    }
}
