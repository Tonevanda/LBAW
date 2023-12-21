<?php

namespace App\Console;

use App\Models\Wallet;
use App\Models\Product;
use App\Models\Purchase;
use Illuminate\Console\Scheduling\Schedule;
use App\Http\Controllers\PurchaseController;
use App\Events\TrackedOrderChanged;
use App\Events\RefundOrCancel;
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
            $purchases = Purchase::where('orderarrivedat', '<=', now())
                                        ->whereNull('refundedat')
                                        ->where('stage_state', '!=', 'delivered')
                                        ->get();
            foreach($purchases as $purchase){
                $purchase->stage_state = "next";
                $new_date = now()->addMinutes(random_int(0, 2))->addSeconds(random_int(0, 30));

                $purchase->update([
                    'stage_state' => 'next',
                    'orderarrivedat' => $new_date
                ]);
                //notification for changed track order
                event(new TrackedOrderChanged(1));
            }           
        })->everyMinute();

        $schedule->call(function() {
            $purchases = Purchase::where('refundedat', '<=', now())
                                        ->get();
            foreach($purchases as $purchase){
                $purchase->delete();
                //notification for refunding or canceling purchase
                event(new RefundOrCancel(1));
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



