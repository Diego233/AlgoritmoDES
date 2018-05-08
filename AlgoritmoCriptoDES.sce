//==============================================================================
//= Desarrollo del algoritmo de encriptado DES en Scilab
//= El programa se realiza para el curso de Seguridad en redes Inalambricas
//= de la Escuela de Ingenieria en Telecomunicaciones de la UNSA
//= Creditos:
//=     Editor: Chacon Cadillo Diego Jaffet
//=             chacond233@gmail.com
//=             djchacon@ieee.org
//=
//= "Pero si alguno de vosotros se ve falto de sabiduría, que la pida a Dios,..."
//= Santiago 1:5
//= 
//= Bibliografia:
//= http://www.satorre.eu/descripcion_algoritmo_des.pdf
//= https://www.youtube.com/watch?v=hTLpMm7m5XY
//= 
//= GitHub
//= https://github.com/Diego233/AlgoritmoDES.git
//==============================================================================


//==============================================================================
//=========================    FUNCIONES PRELIMINARES   ========================
//==============================================================================

function ArrayBinario = estirarEnBits(textPlan)
    // Esta funcion crea un array de bits usando el texto plano 
    // El texto plano debe ser de 8 caracteres o menos y mayor que un caracter
    // De ser mayor de ocho caracteres se tomaran los primeros ocho
    if length(textPlan) < 8 then
        while length(textPlan) < 8
            textPlan = textPlan + "0";
        end
    elseif length(textPlan) == 8 then
        textPlan = textPlan;
        
    elseif length(textPlan) > 8 then
        textPlan = part(textPlan,1:8);
    end
    
    ArrayBinario = []
    binarios = dec2bin(ascii(textPlan),8)
    for i=1:8
        for j=1:8
            ArrayBinario = [ArrayBinario, part(binarios(i),j)];
        end
    end
    ArrayBinario = strtod(ArrayBinario)
endfunction

function out = permutador(ArrayBinario, MatrizPermutadora)
    //Esta funcion permuta los valores de Array de bits en funcion de la MAtriz 
    //Permutadora la salida sera una matriz de datos binarios con la forma
    //de La MAtriz Permutadora
    [f, c] = size(MatrizPermutadora);
    out = ones(f, c);
    for i = 1:f
        for j = 1:c
            out(i,j) = ArrayBinario(MatrizPermutadora(i,j));
        end
    end
endfunction

function out = RotarMatriz(M, columnas)
    //Esta funcion rota las columnas de una matriz hacia la izquierda
    [f,c] = size(M);
    out = M;
    out = [out(:,columnas+1:c), out(:,1:columnas)]
endfunction

//==============================================================================
//============================    ALGORITMO DES     ============================
//==============================================================================

//INFORMACION DE INICIO

//clave = "ochobits";
//textoPlano = "Este es un texto de pruba para el algoritmo DES";

//1.PROCESAR LA CLAVE

//1.1 Solicitar clave y convertirla en binarios
function Ks = ProcesarClave(clave)

    A = estirarEnBits(clave);
    //1.2 Calcular las subclaves
    
    PC1 =  [57,49,41,33,25,17,9;
            1,58,50,42,34,26,18;
            10,2,59,51,43,35,27;
            19,11,3,60,52,44,36;
            63,55,47,39,31,23,15;
            7,62,54,46,38,30,22;
            14,6,61,53,45,37,29;
            21,13,5,28,20,12,4];
    
    //Calculo de clave Permutada
    clavePermu = permutador(A, PC1);
    
    //Generar llaves
    PC2 =  [14,17,11,24,1,5;
            3,28,15,6,21,10;
            23,19,12,4,26,8;
            16,7,27,20,16,2;
            41,52,31,37,47,55;
            30,40,51,45,33,48;
            44,49,39,56,34,53;
            46,42,50,36,29,32];
            
    Ks = [];
    
    a = [1 1 2 2 2 2 2 2 1 2 2 2 2 2 2 1];
    
    for i = 1:16;
        clavePermu = RotarMatriz(clavePermu, a(i));
        Ks = [Ks; permutador(clavePermu, PC2)];
    end
    
    Ks = matrix(Ks, 8, 6, 16);

endfunction
//2. PROCESAR EL TEXTO PLANO

function TextoPermut = PreProcesarTexto(textoPlano)

    IP =  [58,50,42,34,26,18,10,2;
           60,52,44,36,28,20,12,4;
           62,54,46,38,30,22,14,6;
           64,56,48,40,32,24,16,8;
           57,49,41,33,25,17,9,1;
           59,51,43,35,27,19,11,3;
           61,53,45,37,29,21,13,5;
           63,55,47,39,31,23,15,7];
    
    //Separamos en bloques de ocho caractere, si faltan no hay problema
    T = [];
    while length(textoPlano) > 8;
        T = [T, part(textoPlano,1:8)];
        textoPlano = part(textoPlano,9:length(textoPlano));
    end
    T = [T, textoPlano];
    
    //Converimos cada caracter en binario cada grupo de ocho caracteres en una bloque y 
    //juntamos los bloques en una matriz de 3 dimenciones
    TBinarios = [];
    for i=1:length(length(T));
        TBinarios = [TBinarios, estirarEnBits(T(i))];
    end
    TBinarios = matrix(TBinarios,8,8, length(length(T)));
    
    //Realizamos la permutacion con IP (Permutacion Inicial) a cada bloque y creamos
    //una nueva matriz de 3 dimenciones
    TextoPermut = [];
    for i=1:length(length(T));
        TextoPermut = [TextoPermut; permutador(TBinarios(:,:,i),IP)];
    end
    TextoPermut = matrix(TextoPermut,8,8, length(length(T)));
endfunction
//Ya todo esta listo para continuar con la segunda parte del algoritmo

//3. Dividimos cada bloque de 64en dos grupos de 32 bits y lo expandimos a 48 bits

function expa = expancion(Bloque, Llave)
    //La función f de la red de Feistel se compone de una permutación de
    //expansión (E), que convierte el bloque correspondiente de 32 bits en uno de
    //48. Después realiza una or-exclusiva con el valor Llave-i (Ks-i), también de 48 bits,
    //aplica ocho S-Cajas de 6*4 bits, y efectúa una nueva permutación (P).
    
    E = [32,1,2,3,4,5;  //Matriz de expancion
     4,5,6,7,8,9;
     8,9,10,11,12,13;
     12,13,14,15,16,17;
     16,17,18,19,20,21;
     20,21,22,23,24,25;
     24,25,26,27,28,29;
     28,29,30,31,32,1]
    
    L = Bloque(1:4,:)   //Parte Izquierda(superior) del bloque
    R = Bloque(5:8,:)   //Parte Derecha  (inferior) del bloque
    Ex =  bitxor(permutador(R,E),Llave)             //Matriz inicial de funcion
 
    //Sustitucion S-Cajas
    
    S =  [14 4 13 1 2 15 11 8 3 10 6 12 5 9 0 7;    //caja S1
          0 15 7 4 14 2 13 1 10 6 12 11 9 5 3 8;
          4 1 14 8 13 6 2 11 15 12 9 7 3 10 5 0;
          15 12 8 2 4 9 1 7 5 11 3 14 10 0 6 13;
          15 1 8 14 6 11 3 4 9 7 2 13 12 0 5 10;    //casa S2
          3 13 4 7 15 2 8 14 12 0 1 10 6 9 11 5;
          0 14 7 11 10 4 13 1 5 8 12 6 9 3 2 15;
          13 8 10 1 3 15 4 2 11 6 7 12 0 5 14 9;
          10 0 9 14 6 3 15 5 1 13 12 7 11 4 2 8;    //caja S3
          13 7 0 9 3 4 6 10 2 8 5 14 12 11 15 1;
          13 6 4 9 8 15 3 0 11 1 2 12 5 10 14 7;
          1 10 13 0 6 9 8 7 4 15 14 3 11 5 2 12;
          7 13 14 3 0 6 9 10 1 2 8 5 11 12 4 15;    //caja S4
          13 8 11 5 6 15 0 3 4 7 2 12 1 10 14 9;
          10 6 9 0 12 11 7 13 15 1 3 14 5 2 8 4;
          3 15 0 6 10 1 13 8 9 4 5 11 12 7 2 14;
          2 12 4 1 7 10 11 6 8 5 3 15 13 0 14 9;    //caja S5
          14 11 2 12 4 7 13 1 5 0 15 10 3 9 8 6;
          4 2 1 11 10 13 7 8 15 9 12 5 6 3 0 14;
          11 8 12 7 1 14 2 13 6 15 0 9 10 4 5 3;
          12 1 10 15 9 2 6 8 0 13 3 4 14 7 5 11;    //caja S6
          10 15 4 2 7 12 9 5 6 1 13 14 0 11 3 8;
          9 14 15 5 2 8 12 3 7 0 4 10 1 13 11 6;
          4 3 2 12 9 5 15 10 11 14 1 7 6 0 8 13;
          4 11 2 14 15 0 8 13 3 12 9 7 5 10 6 1;    //caja S7
          13 0 11 7 4 9 1 10 14 3 5 12 2 15 8 6;
          1 4 11 13 12 3 7 14 10 15 6 8 0 5 9 2;
          6 11 13 8 1 4 10 7 9 5 0 15 14 2 3 12;
          13 2 8 4 6 15 11 1 10 9 3 14 5 0 12 7;    //caja S8
          1 15 13 8 10 3 7 4 12 5 6 11 0 14 9 2;
          7 11 4 1 9 12 14 2 0 6 10 13 15 3 5 8;
          2 1 14 7 4 10 8 13 15 12 9 0 3 5 6 11];
    
    S = matrix(S,4,16,8);   //Reacomodo de las cajas en 3 dimenciones
    
    ex = []                 //vector que tendra los valores seleccionados de
                            //las cajas S en funcion de Ex
    
    for i = 1:8;
        filaS = [Ex(i,:)(1),Ex(i,:)(6)]
        columnaS = Ex(i,:)(2:5)
        filaS = bin2dec(strcat(string(filaS)))+1
        columnaS = bin2dec(strcat(string(columnaS)))+1
        
        ex = [ex, S(filaS,columnaS,i)]
    end
    
    ex = dec2bin(ex,4)      //volvemos binarios los valores de ex (String)
    
    expa = []               //vector que convertira los string de ex en una
                            //cadena de int's
    
    for i=1:8
        for j=1:4
            expa = [expa, part(ex(i),j)];
        end
    end
    
    expa = matrix(strtod(expa),4,8)' //se arma la matriz de 8x4
    
    P2 = [22,19,32,2,5,1,29,16;      // Matriz permutadora de expa
          11,13,27,8,18,15,12,7;
          4,30,3,24,31,23,28,20;
          25,6,9,14,10,26,17,21]
    expa = permutador(expa,P2)
    
    expa = [R; bitxor(expa,L)]       // Aplicamos bitxor a la matriz permutada
                                     // con la parte Izquierda(superior) del 
                                     // bloque inicial y lo juntamos con la 
                                     // parte derecha(inferior) para formar una 
                                     // matriz de 8x8
endfunction   

Ks = ProcesarClave(clave)
TextoPermut = PreProcesarTexto(textoPlano)
//Aplicamos la funcion expancion a todos los bloques del texto a cifrar

function TexCifrado = CifradorDES(TextoPermut,Ks)

    IPI = [40 8 48 16 56 24 64 32;
          39 7 47 15 55 23 63 31;
          38 6 46 14 54 22 62 30;
          37 5 45 13 53 21 61 29;
          36 4 44 12 52 20 60 28;
          35 3 43 11 51 19 59 27;
          34 2 42 10 50 18 58 26;
          33 1 41 9 49 17 57 25]
    [f,c,bloque]=size(TextoPermut)
    TP = []
    for f = 1:bloque
        for v = 1:16;
            TextoPermut(:,:,bloque) = expancion(TextoPermut(:,:,bloque), Ks(:,:,i))
        end
        //Intercambio de R con L para la presalida y permutar con Permutador Inicial Inverso
        TP=[TP; permutador([TextoPermut(5:8,:,bloque);TextoPermut(1:4,:,bloque)],IPI)]
    end
    
    TP = matrix(TP,8,8,bloque)
    
    //devolvemos los bloques a caracteres
    TexCifrado = []
    for a=1:bloque
        for b=1:8
            TexCifrado=[TexCifrado ascii(bin2dec(strcat(string(TP(b,:,a)))))]
            disp(TexCifrado, length(TexCifrado))
        end
    end
    
    TexCifrado = strcat(TexCifrado)
endfunction

TexCifrado = CifradorDES(TextoPermut,Ks)

//Desencriptación:
//Usar el mismo proceso descrito con anterioridad pero empleando las
//subclaves en orden inverso, esto es, en lugar de aplicar K(1) para la primera
//iteración aplicar K(16), K(15) para la segunda y así hasta K(1).
