<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/productos_create', [Controllers\ProductoController::class, 'create'])->name('productos_create');
Route::post('/productos_store', [Controllers\ProductoController::class, 'store'])->name('productos_store');
Route::get('/productos_index', [Controllers\ProductoController::class, 'index'])->name('productos_index');
Route::delete('/productos_delete/{id}', [Controllers\ProductoController::class, 'destroy'])->name('productos_delete');
Route::get('/productos_edit/{id}', [Controllers\ProductoController::class, 'edit'])->name('productos_edit');
Route::put('/productos_update/{id}', [Controllers\ProductoController::class, 'update'])->name('productos_update');
Route::view('/home', 'home')->name('home');