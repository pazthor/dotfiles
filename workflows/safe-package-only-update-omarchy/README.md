Safe package-only update path would be to avoid omarchy update, because that runs Omarchy git update + migrations. Use only package
 steps, for example:

 ```bash
   omarchy snapshot create                                                                                                             
   omarchy update keyring                                                                                                              
   omarchy update system pkgs                                                                                                          
   omarchy update aur pkgs                                                                                                             
   omarchy update restart                                                                                                              
 ```
