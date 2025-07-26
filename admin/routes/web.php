<?php

use Illuminate\Support\Facades\Route;

Route::get('hello', function () {
    return view('welcome');
});

Route::get('info', function () {
    phpinfo();
});

Route::prefix('horizon')->namespace('Laravel\Horizon\Http\Controllers')->group(function () {
    Route::get('/', 'HomeController@index')->name('horizon.index');
    require base_path('vendor/laravel/horizon/routes/web.php');
});


