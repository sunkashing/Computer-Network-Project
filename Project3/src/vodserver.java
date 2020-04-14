import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;

public class vodserver implements Runnable {
    private Socket client = null;
    private InputStream input;
    private OutputStream output;
    private BufferedReader reader;
    private PrintWriter outputHeader;
    private BufferedOutputStream outputBody;
    private String method;
    private int fileLength;
    private static final File ROOT = new File("./content");
    private static final String DEFAULT_HTML = "index.html";

    public vodserver(Socket client) throws IOException {
        this.client = client;
        this.input = client.getInputStream();
        this.output = client.getOutputStream();
        this.outputHeader = new PrintWriter(this.output);
        this.outputBody = new BufferedOutputStream(this.output);
    }

    @Override
    public void run() {
        try{
            String filePath = read();
            if (filePath != null && filePath.equals("/")) {
                filePath = DEFAULT_HTML;
                this.method = getContentType("index.html");
            }
            response(filePath);
        } catch (IOException e) {
            System.err.println("Server error : " + e);
        } finally {
            try {
                this.reader.close();
                this.outputHeader.close();
                this.outputBody.close();
                this.client.close();
            } catch (IOException e) {
                e.printStackTrace();
            }

        }
    }

    public static void main(String[] args) throws Exception{
        ServerSocket server = new ServerSocket(30002);
        try {
            Socket newClient = null;
            while(true) {
                newClient = server.accept();
                new Thread(new vodserver(newClient)).start();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void response(String filePath) {
        File file = new File(ROOT, filePath);
        this.fileLength = (int) file.length();
        if (file.exists()) {
            try {
                writeHeader();
                writeBody(file);
            } catch (Exception e) {
                e.printStackTrace();
            }

        } else {
            StringBuilder error = new StringBuilder();
            error.append("HTTP /1.1 400 file not found /r/n");
            error.append("Content-Type:text/html \r\n");
            error.append("Content-Length:20 \r\n").append("\r\n");
            error.append("<h1 >File Not Found..</h1>");
            try {
                this.output.write(error.toString().getBytes());
                this.output.flush();
                this.output.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void writeHeader() {
        this.outputHeader.println("HTTP/1.1 200 ok");
        this.outputHeader.println("Content-Type:text/html; charset=UTF-8");
        this.outputHeader.println("Content-Length:" + this.fileLength);
        this.outputHeader.println("Connection: Keep-Alive");
        this.outputHeader.println();
        this.outputHeader.flush();
    }

    private void writeBody(File file) throws IOException {

        FileInputStream fileIn = null;
        byte[] fileBytes = new byte[this.fileLength];
        try {
            fileIn = new FileInputStream(file);
            fileIn.read(fileBytes);
        } finally {
            if (fileIn != null) fileIn.close();
        }
        this.outputBody.write(fileBytes, 0, this.fileLength);
        this.outputBody.flush();

    }

    private String read() throws IOException {
        try {
            this.reader = new BufferedReader(new InputStreamReader(this.input));
            String readLine = this.reader.readLine();
            if (readLine == null) {
                return null;
            }
            String[] split = readLine.split(" ");
            if (split.length != 3) {
                return null;
            }
            System.out.println(readLine);
            this.method = split[0].toUpperCase();
            return split[1];
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    private String getContentType(String fileName) {
        if (fileName.endsWith(".txt"))
            return "text/plain";
        else if (fileName.endsWith(".css"))
            return "text/css";
        else if (fileName.endsWith(".htm") || fileName.endsWith(".html"))
            return "text/html";
        else if (fileName.endsWith(".gif"))
            return "image/gif";
        else if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg") )
            return "image/jpeg";
        else if (fileName.endsWith(".png"))
            return "image/png";
        else if (fileName.endsWith(".js"))
            return "application/javascript";
        else if (fileName.endsWith(".webm"))
            return "video/webm";
        else if (fileName.endsWith(".ogg") || fileName.endsWith(".mp4"))
            return "video/mp4";
        else
            return "application/octet-stream";
    }

}
