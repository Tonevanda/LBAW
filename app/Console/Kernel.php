<?php

namespace App\Console;

use App\Models\Product;
use App\Models\Purchase;
use Illuminate\Console\Scheduling\Schedule;
use App\Http\Controllers\PurchaseController;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{


    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        $schedule->command('auth:clear-resets')->everyFifteenMinutes();
        $schedule->call(function() {
            error_log(now());
            $purchases = Purchase::where('orderarrivedat', '<=', now())
                                        ->where('stage_state', '!=', 'delivered')
                                        ->get();
            foreach($purchases as $purchase){
                $purchase->stage_state = "next";
                $new_date = now()->addMinutes(random_int(0, 2))->addSeconds(random_int(0, 30));
                $purchase->update([
                    'stage_state' => 'next',
                    'orderarrivedat' => $new_date
                ]);

            }           
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



