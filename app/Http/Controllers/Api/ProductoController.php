<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Producto;;
use Illuminate\Support\Facades\Storage;

class ProductoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return response()->json(Producto::all());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required|numeric',
            'cantidad' => 'required|integer',
            'categoria_id' => 'required|exists:categorias,id',
            'imagen' => 'nullable|image|mimes:jpg,png,jpeg,gif|max:2048',
        ]);

        if ($request->hasFile('imagen')) {
            $imagenPath = $request->file('imagen')->store('public/images');
            $nombreArchivo = basename($imagenPath);
            $validation['imagen'] = $nombreArchivo;
        }

        $producto = Producto::create($validation);

        return response()->json($producto, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }
        return response()->json($producto);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required|numeric',
            'cantidad' => 'required|integer',
            'categoria_id' => 'required|exists:categorias,id',
            'imagen' => 'nullable|image|mimes:jpg,png,jpeg,gif|max:2048',
        ]);

        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        if ($request->hasFile('imagen')) {
            if ($producto->imagen && Storage::exists('public/images/' . $producto->imagen)) {
                Storage::delete('public/images/' . $producto->imagen);
            }

            $imagenPath = $request->file('imagen')->store('public/images');
            $nombreArchivo = basename($imagenPath);
            $validation['imagen'] = $nombreArchivo;
        } else {
            $validation['imagen'] = $producto->imagen;
        }

        $producto->update($validation);

        return response()->json($producto);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $producto = Producto::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        if ($producto->imagen && Storage::exists('public/images/' . $producto->imagen)) {
            Storage::delete('public/images/' . $producto->imagen);
        }

        $producto->delete();

        return response()->json(['message' => 'Producto eliminado']);
    }
}
