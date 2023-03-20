## linux device tree for the nanopi r5c & r5s

<br/>

**build device tree images for the nanopi r5c / r5s**
```
sh make_dtb.sh
```

<i>the build will produce the target file: rk3568-nanopi-r5s.dtb</i>

<br/>

**optional: create symbolic links**
```
sh make_dtb.sh links
```

<i>convenience links to various rk3568 device tree files will be created in the project directory</i>

<br/>

**optional: clean target**
```
sh make_dtb.sh clean
```

