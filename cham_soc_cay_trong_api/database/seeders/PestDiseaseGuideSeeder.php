<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PestDiseaseGuideSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('pest_disease_guides')->truncate();

        $guides = [
            // ========== BỆNH HẠI ==========
            [
                'plant_name' => 'Hoa hồng',
                'disease_name' => 'Bệnh đốm đen (Black Spot)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Xuất hiện các đốm đen tròn trên lá. Lá dần chuyển vàng và rụng sớm.',
                'causes' => 'Nấm Diplocarpon rosae phát triển mạnh trong điều kiện ẩm ướt, mưa nhiều.',
                'prevention' => 'Giữ lá khô ráo khi tưới, tưới nước vào buổi gốc. Cắt tỉa cành để tạo độ thông thoáng.',
                'treatment' => 'Ngắt bỏ lá bệnh và tiêu hủy xa gốc. Phun thuốc diệt nấm sinh học hoặc Mancozeb theo hướng dẫn.',
                'image_url' => null,
                'affected_plants' => 'Hoa hồng (rất phổ biến), Hoa cúc, Hoa mẫu đơn, Hoa trà',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Hồng', 'reason' => 'Cực kỳ nhạy cảm, đặc biệt giống hồng cổ và hồng ngoại'],
                    ['name' => 'Hoa Mẫu Đơn', 'reason' => 'Lá to giữ ẩm lâu, tạo điều kiện cho nấm phát triển'],
                    ['name' => 'Hoa Trà (Camellia)', 'reason' => 'Dễ bị khi trồng ở khu vực ẩm thấp, thiếu nắng'],
                ]),
            ],
            [
                'plant_name' => 'Lan',
                'disease_name' => 'Bệnh thối nhũn (Soft Rot)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Vết bệnh ban đầu như bị luộc nước sôi, sau đó lan nhanh làm thối nhũn lá non, có mùi hôi.',
                'causes' => 'Vi khuẩn Erwinia carotovora xâm nhập qua vết xước, phát triển khi tưới quá nhiều hoặc giá thể úng nước.',
                'prevention' => 'Che mưa, điều chỉnh lượng nước. Phun phòng thuốc sát khuẩn định kỳ. Đảm bảo vườn lan thoáng gió.',
                'treatment' => 'Ngừng tưới nước, cách ly cây bệnh. Cắt bỏ phần thối nhũn và bôi vôi hoặc thuốc sát khuẩn (Physan) vào vết cắt.',
                'image_url' => null,
                'affected_plants' => 'Lan Hồ Điệp (rất phổ biến), Lan Dendrobium, Lan Vanda, Sen đá, Xương rồng',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Lan Hồ Điệp', 'reason' => 'Thân mọng nước, bộ rễ nhạy cảm với úng nước'],
                    ['name' => 'Lan Dendrobium', 'reason' => 'Dễ bị khi giá thể giữ ẩm quá lâu'],
                    ['name' => 'Sen Đá', 'reason' => 'Lá mọng nước rất dễ thối nhũn khi ẩm cao'],
                ]),
            ],
            [
                'plant_name' => 'Cà chua',
                'disease_name' => 'Bệnh mốc sương (Late Blight)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Lá có vết đốm màu xanh tái, sau đó chuyển nâu đen và chết khô ngọn. Quả bị thối nâu.',
                'causes' => 'Nấm Phytophthora infestans phát sinh trong tiết trời lạnh và độ ẩm cao.',
                'prevention' => 'Chọn giống kháng bệnh. Thu dọn tàn dư vụ trước. Trồng thưa để thông thoáng.',
                'treatment' => 'Sử dụng thuốc bảo vệ thực vật đặc trị hoặc các chế phẩm sinh học như Ridomil Gold.',
                'image_url' => null,
                'affected_plants' => 'Cà chua (rất phổ biến), Khoai tây, Ớt, Cà tím, Dưa chuột',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Dạ Yên Thảo', 'reason' => 'Cùng họ Cà, rất nhạy cảm với nấm Phytophthora'],
                    ['name' => 'Hoa Vạn Thọ', 'reason' => 'Dễ bị mốc sương khi trồng dày vào mùa mưa'],
                    ['name' => 'Hoa Cúc', 'reason' => 'Lá mỏng giữ ẩm, dễ nhiễm khi thời tiết lạnh ẩm'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Bệnh phấn trắng (Powdery Mildew)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Xuất hiện lớp phấn trắng mịn trên mặt lá, thân và nụ hoa. Lá cong, vàng rồi khô dần.',
                'causes' => 'Nấm Erysiphales phát triển trong điều kiện ẩm, thiếu ánh sáng, thông gió kém.',
                'prevention' => 'Trồng cây ở nơi thoáng mát, đủ nắng. Không tưới nước lên lá vào buổi tối. Tỉa bớt cành lá dày.',
                'treatment' => 'Phun dung dịch baking soda pha loãng (1 muỗng cà phê/lít nước + vài giọt xà phòng). Hoặc dùng thuốc trị nấm chuyên dụng.',
                'image_url' => null,
                'affected_plants' => 'Hoa hồng, Hoa cúc, Dưa chuột, Bí ngô, Đậu bắp, Hoa zinnia, Hoa oải hương',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Hồng', 'reason' => 'Giống hồng leo và hồng bụi bị nặng nhất vào mùa ẩm'],
                    ['name' => 'Hoa Zinnia', 'reason' => 'Lá xù xì dễ giữ bào tử nấm, bệnh rất phổ biến'],
                    ['name' => 'Hoa Oải Hương', 'reason' => 'Không chịu được ẩm, phấn trắng xuất hiện nhanh'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Bệnh vàng lá (Leaf Yellowing / Chlorosis)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Lá chuyển vàng từ mép vào gân, hoặc vàng đều toàn lá. Cây còi cọc, chậm phát triển.',
                'causes' => 'Thiếu dinh dưỡng (đặc biệt sắt, magiê, kẽm), pH đất không phù hợp, tưới quá nhiều hoặc quá ít.',
                'prevention' => 'Bón phân cân đối, kiểm tra pH đất định kỳ. Tưới nước đều đặn, không để đất quá ẩm.',
                'treatment' => 'Bổ sung phân vi lượng hoặc phân bón lá chứa sắt chelate. Điều chỉnh pH đất về mức phù hợp (6.0-6.5).',
                'image_url' => null,
                'affected_plants' => 'Hoa Trà (rất phổ biến), Hoa Đỗ Quyên, Hoa Gardenia, Cây chanh, Cây cam',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Gardenia (Dành Dành)', 'reason' => 'Cần đất chua, rất dễ vàng lá khi pH > 6.5'],
                    ['name' => 'Hoa Đỗ Quyên', 'reason' => 'Thiếu sắt nhanh khi đất kiềm, lá vàng từ ngọn'],
                    ['name' => 'Hoa Trà (Camellia)', 'reason' => 'Cần đất chua giàu hữu cơ, dễ bị chlorosis'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Bệnh thán thư (Anthracnose)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Vết bệnh hình tròn hoặc bất định màu nâu đen trên lá, thân, quả. Vết bệnh có viền rõ, tâm khô và thường có vòng đồng tâm.',
                'causes' => 'Nấm Colletotrichum sp. lây qua nước mưa bắn, dụng cụ cắt tỉa chưa khử trùng.',
                'prevention' => 'Khử trùng kéo cắt. Tránh tưới nước lên lá. Thu dọn lá rụng bệnh.',
                'treatment' => 'Phun thuốc gốc đồng (Bordeaux) hoặc Mancozeb. Cắt bỏ và tiêu hủy phần bệnh.',
                'image_url' => null,
                'affected_plants' => 'Hoa lan, Cây xoài, Cây ớt, Hoa hồng, Dâu tây, Cây ổi',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Lan', 'reason' => 'Lá mọng nước dễ bị vết nâu lan rộng nhanh'],
                    ['name' => 'Hoa Hồng', 'reason' => 'Thường bị trên thân cành già, gây khô héo'],
                    ['name' => 'Hoa Hồng Môn (Anthurium)', 'reason' => 'Lá bóng giữ ẩm, dễ nhiễm nấm Colletotrichum'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Bệnh héo rũ (Fusarium Wilt)',
                'type' => 'Bệnh hại',
                'symptoms' => 'Cây héo rũ dù đất vẫn ẩm. Lá vàng từ gốc lên ngọn, một bên cây héo trước. Cắt ngang thân thấy mạch dẫn nâu đen.',
                'causes' => 'Nấm Fusarium oxysporum sống trong đất, xâm nhập qua rễ. Lan truyền qua đất ô nhiễm và dụng cụ.',
                'prevention' => 'Luân canh cây trồng. Dùng giá thể sạch bệnh. Chọn giống kháng bệnh.',
                'treatment' => 'Không có thuốc trị đặc hiệu. Nhổ bỏ cây bệnh và xử lý đất bằng Trichoderma trước khi trồng lại.',
                'image_url' => null,
                'affected_plants' => 'Cà chua, Dưa hấu, Hoa cúc, Hoa cẩm chướng, Cây chuối, Đậu các loại',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Cẩm Chướng', 'reason' => 'Giống rất nhạy cảm, héo nhanh không cứu được'],
                    ['name' => 'Hoa Cúc', 'reason' => 'Nấm Fusarium tấn công rễ gây vàng héo một bên'],
                    ['name' => 'Hoa Đồng Tiền (Gerbera)', 'reason' => 'Bộ rễ yếu, dễ nhiễm qua đất ô nhiễm'],
                ]),
            ],

            // ========== SÂU HẠI ==========
            [
                'plant_name' => 'Hoa hồng',
                'disease_name' => 'Rệp (Aphids)',
                'type' => 'Sâu hại',
                'symptoms' => 'Côn trùng nhỏ bám kín ngọn non, mặt dưới lá. Lá bị chùn, ngọn cong quoéo. Tiết dịch nhờn thu hút nấm đen.',
                'causes' => 'Rệp sinh sôi nhanh vào mùa xuân, chích hút nhựa cây gây suy yếu.',
                'prevention' => 'Thường xuyên kiểm tra ngọn non. Trồng cây gia vị (tỏi, hành) xen kẽ để xua đuổi.',
                'treatment' => 'Xịt nước mạnh làm rệp rụng. Phun dung dịch xà phòng pha loãng hoặc dầu Neem (Neem oil).',
                'image_url' => null,
                'affected_plants' => 'Hoa hồng (rất phổ biến), Hoa cúc, Hoa đào, Cây ớt, Rau cải, Đậu bắp',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Hồng', 'reason' => 'Rệp bám dày đặc trên nụ và ngọn non'],
                    ['name' => 'Hoa Cúc', 'reason' => 'Thân mềm, nhựa ngọt thu hút rệp mạnh'],
                    ['name' => 'Hoa Đào', 'reason' => 'Rệp xuất hiện nhiều vào mùa xuân khi ra nụ'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Nhện đỏ (Spider Mites)',
                'type' => 'Sâu hại',
                'symptoms' => 'Lá mất màu xanh, chuyển vàng và có những chấm trắng li ti. Mặt dưới lá có mạng tơ mỏng. Lá khô và rụng.',
                'causes' => 'Nhện đỏ (Tetranychus sp.) phát triển mạnh trong thời tiết nóng, khô. Chúng chích hút nhựa lá.',
                'prevention' => 'Phun sương nước thường xuyên để tăng độ ẩm. Kiểm tra mặt dưới lá định kỳ.',
                'treatment' => 'Phun dầu Neem hoặc xà phòng diệt côn trùng. Nếu nặng, dùng thuốc đặc trị nhện đỏ (Abamectin).',
                'image_url' => null,
                'affected_plants' => 'Hoa hồng, Hoa cúc, Cây ớt, Cà chua, Dưa chuột, Cây chanh, Hoa lan',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Hồng', 'reason' => 'Mặt dưới lá hồng là nơi nhện đỏ ưa thích nhất'],
                    ['name' => 'Hoa Cúc', 'reason' => 'Lá nhiều lông tơ, dễ bị tấn công vào mùa nóng'],
                    ['name' => 'Hoa Lan', 'reason' => 'Nhện đỏ gây vàng lá, giảm khả năng quang hợp'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Sâu cuốn lá (Leaf Rollers)',
                'type' => 'Sâu hại',
                'symptoms' => 'Lá bị cuốn tròn hoặc gập lại, sâu non ẩn bên trong ăn lá. Lá bị khuyết hoặc thủng. Cây suy yếu nếu bị nặng.',
                'causes' => 'Bướm đêm đẻ trứng trên lá, sâu non nở ra cuốn lá để ẩn nấp và ăn.',
                'prevention' => 'Bắt bướm bằng bẫy đèn. Kiểm tra lá cuốn thường xuyên. Trồng cây hương liệu xua đuổi.',
                'treatment' => 'Bóc lá cuốn bắt sâu bằng tay. Phun thuốc trừ sâu sinh học (Bt - Bacillus thuringiensis). Dùng dầu Neem.',
                'image_url' => null,
                'affected_plants' => 'Hoa hồng, Hoa nhài, Cây bưởi, Cây cam, Rau muống, Cây lúa',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Hồng', 'reason' => 'Lá non mềm, sâu cuốn gây hại nụ hoa'],
                    ['name' => 'Hoa Nhài', 'reason' => 'Lá nhỏ mềm, sâu cuốn gây biến dạng nặng'],
                    ['name' => 'Hoa Giấy (Bougainvillea)', 'reason' => 'Lá bông bị sâu cuốn gây mất thẩm mỹ'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Bọ trĩ (Thrips)',
                'type' => 'Sâu hại',
                'symptoms' => 'Lá có vết bạc hoặc sọc trắng. Nụ hoa biến dạng, không nở được hoặc nở méo. Cánh hoa bị xước, mất màu.',
                'causes' => 'Bọ trĩ (Thrips sp.) rất nhỏ, chích hút nhựa tế bào lá và hoa. Phát triển mạnh trong mùa khô nóng.',
                'prevention' => 'Dùng bẫy dính màu xanh dương để theo dõi. Tưới phun sương tăng độ ẩm. Vệ sinh cỏ dại quanh vườn.',
                'treatment' => 'Phun dầu Neem hoặc Spinosad. Luân phiên thuốc để tránh kháng thuốc. Cắt bỏ hoa bị hại nặng.',
                'image_url' => null,
                'affected_plants' => 'Hoa hồng, Hoa lan, Hoa cúc, Hoa lay ơn, Ớt, Dưa hấu, Hoa đồng tiền',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Lay Ơn (Gladiolus)', 'reason' => 'Cánh hoa mỏng bị bọ trĩ phá hủy nhanh'],
                    ['name' => 'Hoa Đồng Tiền', 'reason' => 'Cánh hoa xước trắng, mất màu nghiêm trọng'],
                    ['name' => 'Hoa Lan', 'reason' => 'Nụ hoa biến dạng, không nở hoặc nở méo mó'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Ốc sên & Sên trần (Snails & Slugs)',
                'type' => 'Sâu hại',
                'symptoms' => 'Lá bị ăn thủng lỗ lớn, đặc biệt ở mép lá. Để lại vết nhờn bóng trên lá và mặt đất. Thường gây hại vào ban đêm.',
                'causes' => 'Ốc sên và sên trần hoạt động mạnh khi trời mưa hoặc ẩm ướt. Ẩn nấp dưới chậu, đá, lá mục.',
                'prevention' => 'Rải vỏ trứng nghiền hoặc tro quanh gốc. Giữ vườn gọn gàng, ít chỗ ẩn nấp. Tưới nước vào buổi sáng.',
                'treatment' => 'Đặt bẫy bia (đĩa bia để qua đêm). Rải bả diệt ốc sên thân thiện môi trường. Bắt bằng tay vào ban đêm.',
                'image_url' => null,
                'affected_plants' => 'Hoa Dạ Yên Thảo, Hoa Cúc, Rau diếp, Dâu tây, Hoa Lili, Mồng tơi, Rau cải',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Dạ Yên Thảo', 'reason' => 'Lá mềm mọng nước, ốc sên ăn rất nhanh'],
                    ['name' => 'Hoa Lili', 'reason' => 'Chồi non bị ốc ăn khiến cây không ra hoa'],
                    ['name' => 'Hoa Cúc', 'reason' => 'Lá sát mặt đất dễ bị tấn công ban đêm'],
                ]),
            ],
            [
                'plant_name' => 'Tất cả',
                'disease_name' => 'Bọ phấn trắng (Whiteflies)',
                'type' => 'Sâu hại',
                'symptoms' => 'Đám côn trùng nhỏ trắng bay lên khi chạm vào cây. Lá vàng, dính nhờn. Có nấm đen (muội) phát triển trên dịch tiết.',
                'causes' => 'Bọ phấn trắng (Bemisia tabaci) chích hút nhựa cây và truyền virus. Sinh sôi nhanh trong thời tiết ấm.',
                'prevention' => 'Dùng bẫy dính màu vàng. Kiểm tra mặt dưới lá thường xuyên. Thả bọ rùa (thiên địch).',
                'treatment' => 'Phun xà phòng diệt côn trùng hoặc dầu Neem. Dùng máy hút bụi nhỏ để hút bọ vào buổi sáng sớm.',
                'image_url' => null,
                'affected_plants' => 'Cà chua (rất phổ biến), Ớt, Bắp cải, Hoa Trạng Nguyên, Hoa Phong Lữ, Dưa chuột',
                'top_affected_flowers' => json_encode([
                    ['name' => 'Hoa Trạng Nguyên', 'reason' => 'Mặt dưới lá là nơi bọ phấn sinh sản mạnh'],
                    ['name' => 'Hoa Phong Lữ (Geranium)', 'reason' => 'Lá thơm nhưng vẫn bị bọ phấn tấn công'],
                    ['name' => 'Hoa Dâm Bụt', 'reason' => 'Dịch ngọt trên lá thu hút bọ phấn và nấm muội'],
                ]),
            ],
        ];

        DB::table('pest_disease_guides')->insert($guides);
    }
}
