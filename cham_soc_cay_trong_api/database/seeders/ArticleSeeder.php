<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ArticleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $articles = [
            [
                'title' => '5 loại rau dễ trồng tại nhà',
                'subtitle' => 'Bắt đầu với những loại rau ngắn ngày, ít công chăm mà vẫn dễ thu hoạch.',
                'category' => 'Rau tại nhà',
                'read_time' => '4 phút',
                'icon_name' => 'eco',
                'start_color' => '#7CCF7A',
                'end_color' => '#2FAE66',
                'quick_tips' => [
                    'Ưu tiên chậu có lỗ thoát nước.',
                    'Đặt chậu nơi có nắng nhẹ 4-6 giờ mỗi ngày.',
                    'Chỉ tưới khi lớp đất mặt đã bắt đầu khô.',
                ],
                'sections' => [
                    [
                        'heading' => 'Vì sao nên bắt đầu từ rau dễ trồng',
                        'body' => 'Nếu mới tập trồng cây, bạn nên chọn rau lớn nhanh, dễ quan sát và dễ sửa sai. Nhóm rau này giúp bạn làm quen với đất, nước và ánh sáng mà không cần quy trình quá phức tạp.',
                        'bullets' => [],
                    ],
                    [
                        'heading' => '5 lựa chọn để bắt đầu',
                        'body' => 'Đây là những loại rau phù hợp với ban công, sân thượng hoặc cửa sổ có nắng:',
                        'bullets' => [
                            'Rau muống: lên nhanh, dễ nảy mầm, cắt xong vẫn có thể lên đợt mới.',
                            'Cải xanh: chu kỳ ngắn, lá phát triển nhanh và dễ nhận biết thiếu nước.',
                            'Xà lách: hợp với chậu nông, dễ ăn sống và không cần chăm quá tay.',
                            'Mồng tơi: chịu nóng tốt, leo nhanh và thu hoạch được nhiều lần.',
                            'Húng quế: vừa làm rau vừa xua một số côn trùng nhỏ.',
                        ],
                    ],
                    [
                        'heading' => 'Cách trồng nhanh trong chậu',
                        'body' => 'Bạn có thể bắt đầu đơn giản, không cần dùng quá nhiều vật tư.',
                        'bullets' => [
                            'Trộn đất tơi xốp với phân hữu cơ hoai mục.',
                            'Gieo hạt mỏng, phủ một lớp đất nhẹ rồi phun sương.',
                            'Khi cây có 2-3 lá thật, tỉa bớt cây yếu để cây còn lại có chỗ phát triển.',
                            'Bổ sung phân hữu cơ loãng 7-10 ngày một lần.',
                        ],
                    ],
                    [
                        'heading' => 'Dấu hiệu cây đang phát triển tốt',
                        'body' => 'Lá mới ra đều, màu xanh tự nhiên, thân đứng và đất không bị úi nước là những dấu hiệu tích cực. Nếu lá nhợt màu, mềm hoặc vàng nhanh, bạn nên kiểm tra lại lịch tưới và ánh sáng.',
                        'bullets' => [],
                    ],
                ],
                'sort_order' => 1,
            ],
            [
                'title' => 'Bao lâu nên tưới rau một lần?',
                'subtitle' => 'Không có lịch tưới cố định cho mọi vườn rau; hãy nhìn đất trước khi nhìn đồng hồ.',
                'category' => 'Tưới nước',
                'read_time' => '5 phút',
                'icon_name' => 'water',
                'start_color' => '#7EC8FF',
                'end_color' => '#377DFF',
                'quick_tips' => [
                    'Tưới vào sáng sớm là dễ nhất.',
                    'Chạm tay vào đất sâu 2-3 cm trước khi tưới.',
                    'Ngày mát trời và ngày mưa cần giảm lượng nước.',
                ],
                'sections' => [
                    [
                        'heading' => 'Điều gì quyết định tần suất tưới',
                        'body' => 'Tần suất tưới phụ thuộc vào thời tiết, kích thước chậu, loại đất và độ lớn của cây. Chậu nhỏ khô nhanh hơn chậu lớn. Đất tơi xốp thoát nước nhanh hơn đất nén chặt. Rau ăn lá thường cần độ ẩm ổn định hơn cây gia vị.',
                        'bullets' => [],
                    ],
                    [
                        'heading' => 'Khung tham khảo để nhớ',
                        'body' => 'Bạn có thể bắt đầu bằng mốc đơn giản sau rồi điều chỉnh theo thực tế:',
                        'bullets' => [
                            'Ngày nắng nóng: kiểm tra đất mỗi sáng, có thể cần tưới 1 lần/ngày.',
                            'Ngày mát trời: thường 1-2 ngày mới cần tưới.',
                            'Sau khi mới gieo hạt: giữ ẩm bằng phun sương nhẹ, tránh xói mặt đất.',
                            'Khi cây đã lớn: tưới đẫm hơn nhưng giãn cách ra để rễ ăn sâu.',
                        ],
                    ],
                    [
                        'heading' => 'Cách kiểm tra đất đúng nhất',
                        'body' => 'Đưa ngón tay xuống đất khoảng 2-3 cm. Nếu đất còn ẩm, chưa cần tưới. Nếu đất khô, vụn và rời, bạn mới bổ sung nước. Cách này chính xác hơn việc tưới theo giờ cố định.',
                        'bullets' => [],
                    ],
                    [
                        'heading' => 'Lỗi thường gặp',
                        'body' => 'Nhiều người tưới ít nhưng quá nhiều lần khiến rễ nông, cây yếu và dễ nấm bệnh.',
                        'bullets' => [
                            'Không để đĩa lót nước đọng quá lâu dưới chậu.',
                            'Không tưới giữa trưa nắng gắt nếu không thật sự cần thiết.',
                            'Nếu lá héo xuống dù buổi trưa, hãy chờ tới chiều kiểm tra lại trước khi kết luận cây thiếu nước.',
                        ],
                    ],
                ],
                'sort_order' => 2,
            ],
            [
                'title' => 'Xử lý sâu bệnh nhẹ không cần thuốc mạnh',
                'subtitle' => 'Phát hiện sớm và xử lý đúng điểm thường hiệu quả hơn phun rộng cả vườn.',
                'category' => 'Sâu bệnh',
                'read_time' => '6 phút',
                'icon_name' => 'shield',
                'start_color' => '#FFC977',
                'end_color' => '#F27A3D',
                'quick_tips' => [
                    'Kiểm tra mặt dưới lá 2-3 ngày một lần.',
                    'Cắt bỏ lá bị bệnh sớm để tránh lây lan.',
                    'Giữ vườn thông thoáng để giảm ẩm độ tồn đọng.',
                ],
                'sections' => [
                    [
                        'heading' => 'Nhận biết sớm trước khi bùng dịch',
                        'body' => 'Lá bị chấm trắng, đốm nâu nhỏ, vết nhai lỗ chỗm hoặc mặt dưới lá có côn trùng ti li là dấu hiệu bạn nên xử lý ngay. Xử lý ở giai đoạn nhẹ sẽ tiết kiệm công hơn rất nhiều so với để lan rộng.',
                        'bullets' => [],
                    ],
                    [
                        'heading' => 'Các bước xử lý an toàn',
                        'body' => 'Bạn có thể áp dụng quy trình nhẹ trước khi nghĩ đến thuốc mạnh:',
                        'bullets' => [
                            'Tách chậu bị nhiễm khỏi khu vực còn lại.',
                            'Cắt bỏ lá hỏng, lá có trứng và lá chạm đất.',
                            'Rửa nhẹ mặt dưới lá bằng nước sạch nếu sâu còn ít.',
                            'Phun dung dịch xà phòng sinh học loãng vào lúc chiều mát.',
                        ],
                    ],
                    [
                        'heading' => 'Phòng bệnh quan trọng hơn chữa bệnh',
                        'body' => 'Môi trường bị ngậm nước, quá rậm hoặc thiếu gió là điều kiện để sâu bệnh quay lại.',
                        'bullets' => [
                            'Không trồng quá dày để lá nhanh khô sau khi tưới.',
                            'Vệ sinh chậu, kệ và lá rụng định kỳ.',
                            'Luôn phiên vị trí cây nếu một góc vườn quá ẩm.',
                        ],
                    ],
                    [
                        'heading' => 'Khi nào nên loại bỏ cây',
                        'body' => 'Nếu cây đã thối gốc, nhiễm nấm lan rộng hoặc côn trùng xuất hiện mật độ cao liên tục, nên loại bỏ cây bệnh để bảo vệ cả khay rau. Đất cũ cần được thay hoặc xử lý lại trước khi trồng đợt mới.',
                        'bullets' => [],
                    ],
                ],
                'sort_order' => 3,
            ],
        ];

        foreach ($articles as $article) {
            $article['quick_tips'] = json_encode($article['quick_tips'], JSON_UNESCAPED_UNICODE);
            $article['sections'] = json_encode($article['sections'], JSON_UNESCAPED_UNICODE);
            $article['is_published'] = true;
            $article['created_at'] = now();
            $article['updated_at'] = now();

            DB::table('articles')->updateOrInsert(
                ['title' => $article['title']],
                $article
            );
        }
    }
}
