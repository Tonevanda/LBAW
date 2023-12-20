<?php

namespace App\Console;

use App\Models\Product;
use App\Models\Purchase;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{


    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        //$schedule->command('auth:clear-resets')->everyFifteenMinutes();
        $schedule->call(function() {
            Product::where('price', '<', 10000)->update(['price' => 0]);
        })->everyMinute();

    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
