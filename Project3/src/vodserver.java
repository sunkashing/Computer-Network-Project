import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class vodserver implements Runnable {
    private final Socket client;
    private final InputStream input;
    private final OutputStream output;
    private File file;
    private BufferedReader reader;
    private final PrintWriter outputHeader;
    private final BufferedOutputStream outputBody;
    private String method;
    private String contentType;
    private long fileLength;
    private long partFileLength;
    private long startByte;
    private long endByte;
    private static final File ROOT = new File("./content");
    private static final String DEFAULT_HTML = "/index.html";
    private static final String FILE_NOT_FOUND_HTML = "/404.html";
    private static final String INTERNAL_SERVER_ERROR_HTML = "/500.html";

    public vodserver(Socket client) throws IOException {
        this.client = client;
        this.input = client.getInputStream();
        this.output = client.getOutputStream();
        this.outputHeader = new PrintWriter(output);
        this.outputBody = new BufferedOutputStream(output);
        this.startByte = -1;
        this.endByte = -1;
        this.partFileLength = -1;
    }

    @Override
    public void run() {
        try{
            String filePath = read();
            if (filePath != null && filePath.equals("/")) {
                filePath = DEFAULT_HTML;
                this.contentType = getContentType("index.html");
            } else if (filePath == null) {
                filePath = FILE_NOT_FOUND_HTML;
                this.contentType = getContentType("404.html");
            }
            response(filePath);
        } finally {
            try {
                this.output.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) throws Exception{
        ServerSocket server = new ServerSocket(30002);
        try {
            Socket newClient;
            while(true) {
                newClient = server.accept();
                new Thread(new vodserver(newClient)).start();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void response(String filePath) {
        this.file = new File(ROOT, filePath);
        this.fileLength = this.file.length();
        System.out.println("file length: " + this.fileLength);
        this.contentType = getContentType(filePath);
        try {
            writeHeader();
            writeBody();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    private void writeHeader() {
        if (!this.method.equals("GET") && !this.method.equals("HEAD")) {
            this.outputHeader.println("HTTP/1.1 500 Internal Server Error");
        } else if (!this.file.exists()) {
            this.outputHeader.println("HTTP/1.1 404 File Not Found");
        } else {
            if (this.startByte != -1) {
                this.outputHeader.println("HTTP/1.1 206 Partial content");
                if (this.endByte == -1) {
                    this.endByte = this.fileLength - 1;
                }
                this.outputHeader.println(
                        "Content-Range: bytes " +
                                this.startByte + "-" + this.endByte + "/" + this.fileLength);
                this.partFileLength = this.endByte - this.startByte + 1;
            } else {
                this.outputHeader.println("HTTP/1.1 200 OK");
            }
            SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
            this.outputHeader.println("Last-Modified:" +  dateFormat.format(file.lastModified()));
        }
        this.outputHeader.println("Accept-Ranges:bytes");
        this.outputHeader.println("Content-Type:" + this.contentType);
        if (this.startByte != -1) {
            this.outputHeader.println("Content-Length:" + this.partFileLength);
        } else {
            this.outputHeader.println("Content-Length:" + this.fileLength);
        }
        this.outputHeader.println("Connection: Keep-Alive");
        this.outputHeader.println("Date: " + new Date());
        this.outputHeader.println();
        this.outputHeader.flush();
    }

    private void writeBody() throws IOException {

        FileInputStream fileIn = null;
        byte[] fileBytes = new byte[1024 * 10];
        fileIn = new FileInputStream(this.file);
        int length = 0;
        if (this.startByte != -1) {
            fileIn.skip(this.startByte);
        }
        try {
            while ((length = fileIn.read(fileBytes, 0, fileBytes.length)) != -1) {
                this.outputBody.write(fileBytes, 0, length);
            }
        } finally {
            fileIn.close();
        }
        this.outputBody.flush();

    }

    private String read() {
        try {
            this.reader = new BufferedReader(new InputStreamReader(this.input));
            String readLine = this.reader.readLine();
            if (readLine == null) {
                this.method = "*";
                return null;
            }
            String[] split = readLine.split(" ");
            if (split.length != 3) {
                this.method = "*";
                return null;
            }
            System.out.println(readLine);
            this.method = split[0].toUpperCase();

            while(this.reader.ready() && (readLine = this.reader.readLine()) != null){
                System.out.println(readLine);
                if (readLine.startsWith("Range:")) {
                    if (!readLine.contains("bytes=")) {
                        break;
                    }
                    readLine = readLine.substring(readLine.lastIndexOf("=") + 1);
                    System.out.println(readLine);
                    String[] bytes = readLine.split("-");
                    this.startByte = Long.parseLong(bytes[0]);
                    if (bytes.length == 2) {
                        this.endByte = Long.parseLong(bytes[1]);
                    }
                    System.out.println(Arrays.toString(bytes));
                }
            }

            return split[1];
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    private String getContentType(String fileName) {
        if (fileName == null || fileName.endsWith(".htm") || fileName.endsWith(".html"))
            return "text/html";
        else if (fileName.endsWith(".ico"))
            return "image/x-icon";
        else if (fileName.endsWith(".txt"))
            return "text/plain";
        else if (fileName.endsWith(".css"))
            return "text/css";
        else if (fileName.endsWith(".gif"))
            return "image/gif";
        else if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg") )
            return "image/jpeg";
        else if (fileName.endsWith(".png"))
            return "image/png";
        else if (fileName.endsWith(".js"))
            return "application/javascript";
        else if (fileName.endsWith(".webm") || fileName.endsWith(".mkv"))
            return "video/webm";
        else if (fileName.endsWith(".ogg") || fileName.endsWith(".mp4"))
            return "video/mp4";
        else
            return "application/octet-stream";
    }

}
