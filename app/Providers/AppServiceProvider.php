<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Validator;




class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    
    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if(env('FORCE_HTTPS',false)) {
            error_log('configuring https');

            $app_url = config("app.url");
            URL::forceRootUrl($app_url);
            $schema = explode(':', $app_url)[0];
            URL::forceScheme($schema);
        }
        
        Validator::extend('old_password', function ($attribute, $value, $parameters, $validator) {
            return Hash::check($value, Auth::user()->password);
        });
    }
}

