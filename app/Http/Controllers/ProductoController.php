<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Producto;
use App\Models\Categoria;
use Illuminate\Support\Facades\Storage;


class ProductoController extends Controller
{
    public function create()
    {
        $categorias = Categoria::all();
        return view('productos.productos_create', compact('categorias'));
    }

    public function store(Request $request)
    {

        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required|numeric',
            'cantidad' => 'required|integer',
            'categoria_id' => 'required|exists:categorias,id',
            'imagen' => 'required|image|mimes:jpg,png,jpeg,gif',
        ]);

        $imagenPath = $request->file('imagen')->store('public/images');

        $nombreArchivo = basename($imagenPath);


        Producto::create([
            'nombre' => $validation['nombre'],
            'descripcion' => $validation['descripcion'],
            'precio' => $validation['precio'],
            'cantidad' => $validation['cantidad'],
            'categoria_id' => $validation['categoria_id'],
            'imagen' => $nombreArchivo,
        ]);

        return redirect()->route('productos_index')->with('mensaje', 'Producto creado exitosamente!');
    }

    public function index()
    {
        $productos = Producto::all();
        return view('productos.productos_index', compact('productos'));
    }

    public function destroy($id)
    {
        $producto = Producto::find($id);
        $producto->delete();
        return redirect()->route('productos_index')->with('mensaje', 'Producto eliminado exitosamente!');
    }

    public function edit($id)
    {
        $producto = Producto::find($id);
        $categorias = Categoria::all();
        return view('productos.productos_edit', compact('producto', 'categorias'));
    }

    public function update(Request $request, $id)
    {
        
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
            'precio' => 'required|numeric',
            'cantidad' => 'required|integer',
            'categoria_id' => 'required|exists:categorias,id',
            'imagen' => 'nullable|image|mimes:jpg,png,jpeg,gif',
        ]);
        
        $producto = Producto::find($id);

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

        return redirect()->route('productos_index')->with('mensaje', 'Producto actualizado exitosamente!');
    }


}
