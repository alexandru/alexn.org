# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/path'
require 'tempfile'

describe ImageOptim::Path do
  before do
    stub_const('Path', ImageOptim::Path)
  end

  describe '.convert' do
    it 'returns Path for string' do
      path = 'a'

      expect(Path.convert(path)).to be_a(Path)
      expect(Path.convert(path)).to eq(Path.new(path))

      expect(Path.convert(path)).not_to eq(path)
      expect(Path.convert(path)).not_to be(path)
    end

    it 'returns Path for Pathname' do
      pathname = Pathname.new('a')

      expect(Path.convert(pathname)).to be_a(Path)
      expect(Path.convert(pathname)).to eq(Path.new(pathname))

      expect(Path.convert(pathname)).to eq(pathname)
      expect(Path.convert(pathname)).not_to be(pathname)
    end

    it 'returns same instance for Path' do
      image_path = Path.new('a')

      expect(Path.convert(image_path)).to be_a(Path)
      expect(Path.convert(image_path)).to eq(Path.new(image_path))

      expect(Path.convert(image_path)).to eq(image_path)
      expect(Path.convert(image_path)).to be(image_path)
    end
  end

  describe '#binread' do
    it 'reads binary data' do
      data = (0..255).to_a.pack('c*')

      path = Path.temp_file_path
      path.binwrite(data)

      expect(path.binread).to eq(data)
      if ''.respond_to?(:encoding)
        expect(path.binread.encoding).to eq(Encoding.find('ASCII-8BIT'))
      end
    end
  end

  describe '#replace' do
    let(:src){ Path.temp_file_path }
    let(:dst){ Path.temp_file_path }

    shared_examples 'replaces file' do
      it 'moves data to destination' do
        src.write('src')

        src.replace(dst)

        expect(dst.read).to eq('src')
      end

      it 'removes original file' do
        src.replace(dst)

        expect(src).to_not exist
      end

      it 'preserves attributes of destination file', skip: SkipConditions[:any_file_mode_allowed] do
        mode = 0o666

        dst.chmod(mode)

        src.replace(dst)

        got = dst.stat.mode & 0o777
        expect(got).to eq(mode), format('expected %04o, got %04o', mode, got)
      end

      it 'does not preserve mtime of destination file' do
        time = src.mtime - 1000
        dst.utime(time, time)

        time = dst.mtime

        src.replace(dst)

        expect(dst.mtime).to_not eq(time)
      end

      it 'changes inode of destination', skip: SkipConditions[:inodes_support] do
        expect{ src.replace(dst) }.to change{ dst.stat.ino }
      end
    end

    context 'when src and dst are on same device' do
      before do
        allow_any_instance_of(File::Stat).to receive(:dev).and_return(0)
      end

      include_examples 'replaces file'
    end

    context 'when src and dst are on different devices' do
      before do
        allow_any_instance_of(File::Stat).to receive(:dev, &:__id__)
      end

      include_examples 'replaces file'

      it 'is using temporary file with .tmp extension' do
        expect(src).to receive(:move).with(having_attributes(extname: '.tmp'))

        src.replace(dst)
      end
    end

    context 'when src and dst are on same device, but rename causes Errno::EXDEV' do
      before do
        allow_any_instance_of(File::Stat).to receive(:dev).and_return(0)
        expect(src).to receive(:rename).with(dst.to_s).once.and_raise(Errno::EXDEV)
      end

      include_examples 'replaces file'

      it 'is using temporary file with .tmp extension' do
        expect(src).to receive(:move).with(having_attributes(extname: '.tmp'))

        src.replace(dst)
      end
    end
  end
end
