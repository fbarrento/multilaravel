<?php

namespace App\Providers;

use Filament\Support\Facades\FilamentView;
use Filament\View\PanelsRenderHook;
use Illuminate\Support\Facades\Blade;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;
use Livewire\Livewire;

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
        // Configure Livewire routes for subdirectory
        Livewire::setScriptRoute(function ($handle) {
            return Route::get('/admin/livewire/livewire.js', $handle);
        });

        Livewire::setUpdateRoute(function ($handle) {
            return Route::post('/admin/livewire/update', $handle);
        });

        $this->configurePulse();


    }


    private function configurePulse(): void
    {
        Gate::define('viewPulse', function ($user) {
            if (app()->environment('local')) {
                return true;
            }
           return $user?->email === 'test@example.com';
        });
    }

}
