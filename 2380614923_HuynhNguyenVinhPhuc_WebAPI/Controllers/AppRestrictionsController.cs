using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AppRestrictionsController : ControllerBase
    {
        private readonly KidGuardDbContext _context;

        public AppRestrictionsController(KidGuardDbContext context)
        {
            _context = context;
        }

        // GET: api/AppRestrictions/device/5
        [HttpGet("device/{deviceId}")]
        public async Task<IActionResult> GetByDevice(int deviceId)
        {
            var apps = await _context.AppRestrictions
                .Where(a => a.ChildDeviceId == deviceId)
                .OrderBy(a => a.AppName)
                .ToListAsync();

            return Ok(apps);
        }

        // POST: api/AppRestrictions
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AppRestriction app)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            app.CreatedAt = DateTime.UtcNow;
            _context.AppRestrictions.Add(app);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetByDevice), new { deviceId = app.ChildDeviceId }, app);
        }

        // PUT: api/AppRestrictions/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] AppRestriction updated)
        {
            var app = await _context.AppRestrictions.FindAsync(id);
            if (app == null) return NotFound(new { Message = "Không tìm thấy cấu hình ứng dụng" });

            app.AppName = updated.AppName;
            app.Category = updated.Category;
            app.DailyLimitMinutes = updated.DailyLimitMinutes;
            app.IsBlocked = updated.IsBlocked;

            await _context.SaveChangesAsync();
            return Ok(new { Status = true, Message = "Cập nhật giới hạn ứng dụng thành công", App = app });
        }

        // PUT: api/AppRestrictions/5/toggle-block
        [HttpPut("{id}/toggle-block")]
        public async Task<IActionResult> ToggleBlock(int id)
        {
            var app = await _context.AppRestrictions.FindAsync(id);
            if (app == null) return NotFound(new { Message = "Không tìm thấy cấu hình ứng dụng" });

            app.IsBlocked = !app.IsBlocked;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Status = true,
                Message = app.IsBlocked ? $"Đã khóa ứng dụng {app.AppName}" : $"Đã mở khóa ứng dụng {app.AppName}",
                IsBlocked = app.IsBlocked
            });
        }

        // DELETE: api/AppRestrictions/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var app = await _context.AppRestrictions.FindAsync(id);
            if (app == null) return NotFound(new { Message = "Không tìm thấy cấu hình ứng dụng" });

            _context.AppRestrictions.Remove(app);
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã xóa quy tắc ứng dụng" });
        }
    }
}
