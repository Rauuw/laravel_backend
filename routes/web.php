<?php

use App\Http\Controllers\Api\ProductoController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers;

Route::get('/', function () {
    return view('home');
});

Route::get('/productos_create', [Controllers\ProductoController::class, 'create'])->name('productos_create');
Route::post('/productos_store', [Controllers\ProductoController::class, 'store'])->name('productos_store');
Route::get('/productos_index', [Controllers\ProductoController::class, 'index'])->name('productos_index');
Route::delete('/productos_delete/{id}', [Controllers\ProductoController::class, 'destroy'])->name('productos_delete');
Route::get('/productos_edit/{id}', [Controllers\ProductoController::class, 'edit'])->name('productos_edit');
Route::put('/productos_update/{id}', [Controllers\ProductoController::class, 'update'])->name('productos_update');

Route::get('/categorias_create', [Controllers\CategoriaController::class, 'create'])->name('categorias_create');
Route::post('/categorias_store', [Controllers\CategoriaController::class, 'store'])->name('categorias_store');
Route::get('/categorias_index', [Controllers\CategoriaController::class, 'index'])->name('categorias_index');
Route::delete('/categorias_delete/{id}', [Controllers\CategoriaController::class, 'destroy'])->name('categorias_delete');
Route::get('/categorias_edit/{id}', [Controllers\CategoriaController::class, 'edit'])->name('categorias_edit');
Route::put('/categorias_update/{id}', [Controllers\CategoriaController::class, 'update'])->name('categorias_update');

Route::prefix('api')->group(function () {
    Route::get('productos', [ProductoController::class, 'index']);
    Route::get('productos/{id}', [ProductoController::class, 'show']);
    Route::post('productos', [ProductoController::class, 'store']);
    Route::put('productos/{id}', [ProductoController::class, 'update']);
    Route::delete('productos/{id}', [ProductoController::class, 'destroy']);
});

// Route::view('/home', 'home')->name('home');