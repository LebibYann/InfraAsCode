import { IsString, IsNotEmpty, IsDateString, IsISO8601 } from 'class-validator';

export class CreateTaskDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  content: string;

  @IsDateString()
  @IsNotEmpty()
  due_date: string;

  @IsISO8601()
  @IsNotEmpty()
  request_timestamp: string;
}
