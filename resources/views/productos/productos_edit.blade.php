<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous">
    <title>Document</title>
</head>

<body>

    @extends('layouts.app')

    @section('content')
        <form class="row g-3 needs-validation" novalidate action="{{ route('productos_update', $producto) }}" method="POST"  enctype="multipart/form-data">
            @csrf
            @method('PUT')
            <div class="col-md-6">
                <label for="nombre" class="form-label">Nombre del producto</label>
                <input type="text" class="form-control" id="nombre" placeholder="Nombre" name="nombre" value="{{ $producto->nombre }}" required>
                <div class="invalid-feedback">
                    Introduzca un nombre por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-md-6">
                <label for="descripcion" class="form-label">Descripción</label>
                <input type="text" class="form-control" id="descripcion" placeholder="Descripción" name="descripcion" value="{{ $producto->descripcion }}" required>
                <div class="invalid-feedback">
                    Introduzca una descripción por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-md-6">
                <label for="categoria" class="form-label">Categoría</label>
                <select class="form-select" id="categoria" name="categoria_id" required>
                    <option value="">Seleccione una categoría</option>
                    @foreach ($categorias as $categoria)
                        <option value="{{ $categoria->id }}" {{ $categoria->id == $producto->categoria_id ? 'selected' : '' }}>{{ $categoria->nombre }}</option>
                    @endforeach
                </select>
                <div class="invalid-feedback">
                    Seleccione una categoría por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-md-6">
                <label for="precio" class="form-label">Precio</label>
                <input type="number" step="0.01" class="form-control" id="precio" placeholder="20.50" name="precio" value="{{ $producto->precio }}" required>
                <div class="invalid-feedback">
                    Introduzca un precio por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-md-6">
                <label for="cantidad" class="form-label">Cantidad</label>
                <input type="number" class="form-control" id="cantidad" placeholder="10" name="cantidad" value="{{ $producto->cantidad }}" required>
                <div class="invalid-feedback">
                    Introduzca una cantidad por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-md-6">
                <label for="imagen_actual" class="form-label">Imagen actual</label>
                <br>
                <img src="{{ asset('storage/images/'.$producto->imagen) }}" width="100" height="100" class="d-block mx-auto" alt="Imagen del producto">
            </div>
            <div class="col-md-6">
                <label for="imagen" class="form-label">Imagen</label>
                <input type="file" class="form-control" id="imagen" name="imagen" accept="image/*">
                <div class="invalid-feedback">
                    Introduzca una imagen por favor!
                </div>
                <div class="valid-feedback">
                    Campo válido
                </div>
            </div>
            <div class="col-12">
                <button class="btn btn-primary" type="submit">Editar producto</button>
            </div>
        </form>
        <script>
            (function() {
                'use strict'

                var forms = document.querySelectorAll('.needs-validation')

                Array.prototype.slice.call(forms)
                    .forEach(function(form) {
                        form.addEventListener('submit', function(event) {
                            if (!form.checkValidity()) {
                                event.preventDefault()
                                event.stopPropagation()
                            }

                            form.classList.add('was-validated')
                        }, false)
                    })
            })()
        </script>
    @endsection
</body>

</html>

