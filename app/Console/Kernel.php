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
        //$schedule->command('auth:clear-resets')->everyFifteenMinutes();
        $schedule->call(function() {
            $purchases = Purchase::where('orderedat', '>', now()->toDateString())
                                        ->where('istracked', '=', true)
                                        ->where('stage_state', '!=', 'delivered')
                                        ->get();
            foreach($purchases as $purchase){
                $purchase->stage_state = "next";
                $purchase->save();
                $updated_purchase = Purchase::find($purchase->id);
                error_log($updated_purchase->user_id);
                error_log($updated_purchase->stage_state);
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
