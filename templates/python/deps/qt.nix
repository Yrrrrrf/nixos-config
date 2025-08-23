# A set of dependencies for PyQt/PySide projects
{ pkgs, python3 }: {
  # System libraries
  buildInputs = with pkgs; [
    qt6.qtbase
    qt6.qtwayland
  ];
  # Python-specific packages
  pythonPackages = [
    python3.pkgs.PySide6
  ];
}
