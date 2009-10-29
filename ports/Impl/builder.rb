class Builder
  def initialize pkg, verbose
    @verbose = verbose
  end
  
  def needsBuild
    true
  end

  def clean
  end

  def fetch
  end

  def unpack
    fetch
  end

  def patch
  end

  def pre_build
  end

  def build buildType
  end

  def install buildType
  end

  def post_install
  end

  def dist_clean
  end
end
