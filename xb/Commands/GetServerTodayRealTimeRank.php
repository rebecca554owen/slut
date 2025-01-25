<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Models\ServerShadowsocks;
use App\Models\ServerHysteria;
use App\Models\ServerTrojan;
use App\Models\ServerVless;
use App\Models\ServerVmess;
use App\Models\StatServer;
use App\Services\TelegramService;
use App\Services\StatisticalService;

class GetServerTodayRealTimeRank extends Command
{
    protected $signature = 'xboard:getServerTodayRealTimeRank';
    protected $description = '获取今日实时节点流量排行';

    public function __construct()
    {
        parent::__construct();
    }

    public function handle()
    {
        $this->getServerTodayRealTimeRank();
    }

    private function getServerTodayRealTimeRank()
    {
        $servers = [
            'shadowsocks' => ServerShadowsocks::with(['parent'])->get()->toArray(),
            'v2ray' => ServerVmess::with(['parent'])->get()->toArray(),
            'trojan' => ServerTrojan::with(['parent'])->get()->toArray(),
            'vmess' => ServerVmess::with(['parent'])->get()->toArray(),
            'hysteria' => ServerHysteria::with(['parent'])->get()->toArray(),
            'vless' => ServerVless::with(['parent'])->get()->toArray(),
        ];

        $recordAt = strtotime('today');
        $statService = new StatisticalService();
        $statService->setStartAt($recordAt);
        $stats = $statService->getStatServer();
        $statistics = collect($stats)->map(function ($item) {
            $item['total'] = $item['u'] + $item['d'];
            return $item;
        })->sortByDesc('total')->values()->all();

        foreach ($statistics as $k => $v) {
            foreach ($servers[$v['server_type']] as $server) {
                if ($server['id'] === $v['server_id']) {
                    $statistics[$k]['server_name'] = $server['name'];
                    if ($server['parent']) {
                        $statistics[$k]['server_name'] .= "({$server['parent']['name']})";
                    }
                }
            }
            $statistics[$k]['total'] = $this->formatBytes($statistics[$k]['total']);
        }

        $topStatistics = array_slice($statistics, 0, 3);

        $message = "📊 今日实时节点流量排行\n";
        $message .= "———————————\n";
        foreach ($topStatistics as $index => $stat) {
            $message .= ($index + 1) . "）{$stat['server_name']}：流量使用总计 {$stat['total']}\n";
        }

        $telegramService = new TelegramService();
        $telegramService->sendMessageWithAdmin($this->escapeMarkdown($message));
    }

    private function formatBytes($bytes)
    {
        if ($bytes >= 1024 * 1024 * 1024 * 1024) {
            return round($bytes / (1024 * 1024 * 1024 * 1024), 2) . ' TB';
        } elseif ($bytes >= 1024 * 1024 * 1024) {
            return round($bytes / (1024 * 1024 * 1024), 2) . ' GB';
        } elseif ($bytes >= 1024 * 1024) {
            return round($bytes / (1024 * 1024), 2) . ' MB';
        } else {
            return round($bytes / 1024, 2) . ' KB';
        }
    }

    private function escapeMarkdown($text)
    {
        $escapeChars = ['_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '!'];
        $escapedText = '';
        foreach (str_split($text) as $char) {
            if (in_array($char, $escapeChars)) {
                $escapedText .= '\\' . $char;
            } else {
                $escapedText .= $char;
            }
        }
        return $escapedText;
    }
}
