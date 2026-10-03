using ClosedXML.Excel;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Products.Queries.GetProductExcelTemplate
{
    internal sealed class GetProductExcelTemplateQueryHandler : IQueryHandler<GetProductExcelTemplateQuery, byte[]>
    {
        public Task<Result<byte[]>> Handle(GetProductExcelTemplateQuery request, CancellationToken cancellationToken)
        {
            using var workbook = new XLWorkbook();
            var worksheet = workbook.Worksheets.Add("المنتجات والأجهزة");
            worksheet.RightToLeft = true;

            // 1. Headers matching the Home Appliances Add Product Form
            string[] headers = new[]
            {
                "الباركود*",
                "اسم المنتج (عربي)*",
                "اسم المنتج (إنجليزي)",
                "التصنيف*",
                "الماركة التجارية / البراند",
                "رقم الموديل (Model Number)",
                "اللون",
                "مدة الضمان (بالشهور)",
                "مركز الصيانة / الوكيل",
                "تتبع الرقم التسلسلي (نعم/لا)",
                "سعر الشراء (التكلفة)*",
                "سعر البيع قطاعي*",
                "سعر البيع جملة",
                "الرصيد الأولي (الكمية بالمخزن)",
                "حد إعادة الطلب",
                "الحد الأقصى للمخزون",
                "نسبة الضريبة %",
                "وحدة الصنف الأساسية",
                "رابط الصورة (URL)",
                "الوصف والملاحظات"
            };

            // Write and style Header row
            for (int col = 0; col < headers.Length; col++)
            {
                var cell = worksheet.Cell(1, col + 1);
                cell.Value = headers[col];
                cell.Style.Font.Bold = true;
                cell.Style.Font.FontSize = 11;
                cell.Style.Font.FontColor = XLColor.White;
                cell.Style.Fill.BackgroundColor = XLColor.FromArgb(15, 23, 42); // Slate 900
                cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                cell.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            }
            worksheet.Row(1).Height = 28;

            // Sample Row 1: ثلاجة شارب (نوفروست، ضمان 10 سنوات، تتبع سيريال)
            worksheet.Cell(2, 1).SetValue("6221234567890");
            worksheet.Cell(2, 2).SetValue("ثلاجة شارب 18 قدم نوفروست ديجيتال انفرتر - استانلس");
            worksheet.Cell(2, 3).SetValue("Sharp Refrigerator 18 Cu.Ft NoFrost Digital Inverter Stainless");
            worksheet.Cell(2, 4).SetValue("ثلاجات وديب فريزر");
            worksheet.Cell(2, 5).SetValue("شارب");
            worksheet.Cell(2, 6).SetValue("SJ-PC58A-ST");
            worksheet.Cell(2, 7).SetValue("فضي استانلس");
            worksheet.Cell(2, 8).SetValue(120);
            worksheet.Cell(2, 9).SetValue("العربي جروب 19319");
            worksheet.Cell(2, 10).SetValue("نعم");
            worksheet.Cell(2, 11).SetValue(26500.00);
            worksheet.Cell(2, 12).SetValue(28900.00);
            worksheet.Cell(2, 13).SetValue(27800.00);
            worksheet.Cell(2, 14).SetValue(8);
            worksheet.Cell(2, 15).SetValue(2);
            worksheet.Cell(2, 16).SetValue(25);
            worksheet.Cell(2, 17).SetValue(0);
            worksheet.Cell(2, 18).SetValue("قطعة");
            worksheet.Cell(2, 19).SetValue("https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5");
            worksheet.Cell(2, 20).SetValue("ثلاجة شارب انفرتر موفرة للطاقة مع خاصية البلازما كلاستر وضمان 10 سنوات");

            // Sample Row 2: شاشة سامسونج سمارت (ضمان سنتين، تتبع سيريال)
            worksheet.Cell(3, 1).SetValue("6229876543210");
            worksheet.Cell(3, 2).SetValue("شاشة سامسونج 55 بوصة Smart 4K UHD برسيفر داخلي");
            worksheet.Cell(3, 3).SetValue("Samsung 55 Inch Smart 4K UHD TV Internal Receiver");
            worksheet.Cell(3, 4).SetValue("شاشات وتلفزيونات");
            worksheet.Cell(3, 5).SetValue("سامسونج");
            worksheet.Cell(3, 6).SetValue("UA55CU7000");
            worksheet.Cell(3, 7).SetValue("أسود");
            worksheet.Cell(3, 8).SetValue(24);
            worksheet.Cell(3, 9).SetValue("سامسونج مصر 16580");
            worksheet.Cell(3, 10).SetValue("نعم");
            worksheet.Cell(3, 11).SetValue(16200.00);
            worksheet.Cell(3, 12).SetValue(18000.00);
            worksheet.Cell(3, 13).SetValue(17200.00);
            worksheet.Cell(3, 14).SetValue(15);
            worksheet.Cell(3, 15).SetValue(3);
            worksheet.Cell(3, 16).SetValue(40);
            worksheet.Cell(3, 17).SetValue(0);
            worksheet.Cell(3, 18).SetValue("قطعة");
            worksheet.Cell(3, 19).SetValue("https://images.unsplash.com/photo-1593359677879-a4bb92f829d1");
            worksheet.Cell(3, 20).SetValue("شاشة كريستال بدقة 4K معالج Crystal 4K ورسيفر مدمج وواي فاي");

            // Sample Row 3: غسالة إل جي بالبخار (ضمان 5 سنوات، تتبع سيريال)
            worksheet.Cell(4, 1).SetValue("6225544332211");
            worksheet.Cell(4, 2).SetValue("غسالة إل جي 8 كيلو فول أوتوماتيك انفرتر ديجيتال بالبخار");
            worksheet.Cell(4, 3).SetValue("LG Washing Machine 8 Kg Front Load Inverter Direct Drive Steam");
            worksheet.Cell(4, 4).SetValue("غسالات ومجففات");
            worksheet.Cell(4, 5).SetValue("LG");
            worksheet.Cell(4, 6).SetValue("F4V5VYP0W");
            worksheet.Cell(4, 7).SetValue("فضي");
            worksheet.Cell(4, 8).SetValue(60);
            worksheet.Cell(4, 9).SetValue("راية للصيانة 19089");
            worksheet.Cell(4, 10).SetValue("نعم");
            worksheet.Cell(4, 11).SetValue(21500.00);
            worksheet.Cell(4, 12).SetValue(23500.00);
            worksheet.Cell(4, 13).SetValue(22800.00);
            worksheet.Cell(4, 14).SetValue(6);
            worksheet.Cell(4, 15).SetValue(2);
            worksheet.Cell(4, 16).SetValue(20);
            worksheet.Cell(4, 17).SetValue(0);
            worksheet.Cell(4, 18).SetValue("قطعة");
            worksheet.Cell(4, 19).SetValue("https://images.unsplash.com/photo-1626806787461-102c1bfaaea1");
            worksheet.Cell(4, 20).SetValue("غسالة بموتور الدفع المباشر وتقنية البخار AI DD وحماية الأقمشة");

            // Sample Row 4: خلاط مولينكس (أجهزة منزلية صغيرة، بدون سيريال)
            worksheet.Cell(5, 1).SetValue("6221122334455");
            worksheet.Cell(5, 2).SetValue("خلاط مولينكس سوبر بلندر 700 وات مع 2 مطحنة");
            worksheet.Cell(5, 3).SetValue("Moulinex Super Blender 700W with 2 Grinders");
            worksheet.Cell(5, 4).SetValue("أجهزة منزلية صغيرة");
            worksheet.Cell(5, 5).SetValue("مولينكس");
            worksheet.Cell(5, 6).SetValue("LM207041");
            worksheet.Cell(5, 7).SetValue("أبيض");
            worksheet.Cell(5, 8).SetValue(12);
            worksheet.Cell(5, 9).SetValue("زهران 19729");
            worksheet.Cell(5, 10).SetValue("لا");
            worksheet.Cell(5, 11).SetValue(1450.00);
            worksheet.Cell(5, 12).SetValue(1750.00);
            worksheet.Cell(5, 13).SetValue(1600.00);
            worksheet.Cell(5, 14).SetValue(25);
            worksheet.Cell(5, 15).SetValue(5);
            worksheet.Cell(5, 16).SetValue(60);
            worksheet.Cell(5, 17).SetValue(0);
            worksheet.Cell(5, 18).SetValue("قطعة");
            worksheet.Cell(5, 19).SetValue("");
            worksheet.Cell(5, 20).SetValue("خلاط ومطحنة فرنسي تجميع مصر شفرات ستانلس ستيل");

            // Format number columns
            for (int r = 2; r <= 5; r++)
            {
                worksheet.Cell(r, 11).Style.NumberFormat.Format = "#,##0.00";
                worksheet.Cell(r, 12).Style.NumberFormat.Format = "#,##0.00";
                worksheet.Cell(r, 13).Style.NumberFormat.Format = "#,##0.00";
                worksheet.Cell(r, 1).Style.NumberFormat.Format = "@"; // Text barcode
                worksheet.Row(r).Height = 22;
            }

            worksheet.Columns().AdjustToContents();

            using var memoryStream = new MemoryStream();
            workbook.SaveAs(memoryStream);

            return Task.FromResult(Result<byte[]>.Success(memoryStream.ToArray()));
        }
    }
}
